import { parse } from "csv-parse/browser/esm";

const P = globalThis.pl;

const cds = await (await fetch("/assets/my-music-catalog/music-catalog - CDs.csv")).text();
parse(cds, (err, data) => {
  if (err) {
    throw err;
  }
  onParse(data);
});

const form = document.getElementById("prolog_form");

form.elements["prolog_query"].addEventListener("input", event => {
  event.target.setCustomValidity("");
});

async function onParse(rows) {
  form.addEventListener("submit", event => {
    event.preventDefault();
    const queryFormElement = form.elements["prolog_query"];
    const query = queryFormElement.value;
    runQuery(rows, query, queryFormElement);
  });
}

async function runQuery(rows, query, queryFormElement) {
  const diagsElement = document.getElementById("prolog_diagnostics");
  const diagsHeading = diagsElement.querySelector("h2");
  const diagsElementLastChild = diagsElement.lastElementChild;
  let diagnosticsMessagesElement = document.createElement("p");
  diagnosticsMessagesElement.innerText = "No warnings and no errors.";
  queryFormElement.setCustomValidity("");

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
  const diagnosticsMessages = [];
  let errorMessage;
  try {
    await session.promiseQuery(query);
  } catch (err) {
    errorMessage = err.toString();
    queryFormElement.setCustomValidity("Invalid Prolog query. Check for syntax errors.");
  }
  for (const warning in session.get_warnings()) {
    diagnosticsMessages.push(warning.toString());
  }
  if (errorMessage) {
    displayDiagnostics();
    return;
  }

  try {
    for await (const answer of session.promiseAnswers()) {
      // empty
    }
  } catch (err) {
    errorMessage = err.toString();
  }
  for (const warning in session.get_warnings()) {
    diagnosticsMessages.push(warning.toString());
  }
  displayDiagnostics();

  function displayDiagnostics() {
    errorMessage && diagnosticsMessages.push(errorMessage);
    if (diagnosticsMessages.length !== 0) {
      diagnosticsMessagesElement = document.createElement("ol");
      for (const message of diagnosticsMessages) {
        const el = document.createElement("li");
        el.innerText = message;
        diagnosticsMessagesElement.appendChild(el);
      }
    }
    diagsElement.replaceChild(diagnosticsMessagesElement, diagsElementLastChild);
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
