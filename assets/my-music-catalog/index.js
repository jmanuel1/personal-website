import { parse } from "csv-parse/browser/esm";

const P = globalThis.pl;

const cds = await (await fetch("/assets/my-music-catalog/music-catalog - CDs.csv")).text();
parse(cds, (err, data) => {
  if (err) {
    throw err;
  }
  onParse(data);
});

async function onParse(rows) {
  const form = document.getElementById("prolog_form");
  form.addEventListener("submit", event => {
    event.preventDefault();
    const query = form.elements["prolog_query"].value;
    runQuery(rows, query);
  });
}

async function runQuery(rows, query) {
  const facts = [];
  for (const data of rows) {
    const [artists, albumName] = data;
    const artistList = artists.split(", ");

    const fact = new P.type.Term('album', [P.fromJavaScript.apply(artistList), P.fromJavaScript.apply(albumName)]);
    facts.push(fact.toString({quoted: true}) + '.');
  }

  const session = P.create();
  try {
    await session.promiseConsult(':- use_module(library(dom)).\n:- use_module(library(js)).\n' + tablePl + facts.join('\n'));
  } catch (err) {
    console.error('during consult', err.toString());
    throw err;
  }
  for (const warning in session.get_warnings()) {
    console.warn('consult warnings', warning.toString());
  }
  await session.promiseQuery(query);
  try {
    for await (const answer of session.promiseAnswers()) {
      console.log(session.format_answer(answer));
    }
  } catch (err) {
    console.error('during answers', err.toString());
    throw err;
  }
  for (const warning in session.get_warnings()) {
    console.warn('query warnings', warning.toString());
  }
}

const tablePl = `
  table(Row) :-
    get_by_id(prolog_results, TableElement),
    create(tr, RowElement),
    row(RowElement, Row),
    append_child(TableElement, RowElement).
  row(_, []).
  row(Element, [Datum | Data]) :-
    create(td, DataElement),
    inner_text(DataElement, Datum),
    append_child(Element, DataElement),
    row(Element, Data).
  inner_text(Element, Text) :- set_prop(Element, innerText, Text).`;
