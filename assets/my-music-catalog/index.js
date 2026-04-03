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

function createPrologResultsTableElement() {
  const el = document.createElement("table");
  el.id = "prolog_results";
  const head = document.createElement("thead");
  const headRow = document.createElement("tr");
  head.appendChild(headRow);
  el.appendChild(head);
  const body = document.createElement("tbody");
  el.appendChild(body);
  return el;
}

let prologResultsTable = createPrologResultsTableElement();

function parseProlog(rules) {
  const session = P.create();
  session.consult(rules);
  return session.rules;
}

const tablePl = `
  table_row(Row) :-
    prolog_results_table(TableElement),
    get_by_tag(TableElement, tbody, TBodyElement),
    create(tr, RowElement),
    row(RowElement, Row),
    append_child(TBodyElement, RowElement).
  table_header(Titles) :-
    prolog_results_table(TableElement),
    get_by_tag(TableElement, thead, THeadElement),
    get_by_tag(THeadElement, tr, THeadRowElement),
    findall(TDataElement, get_by_tag(THeadRowElement, th, TDataElement), TDataElements),
    fill_table_row(Titles, TDataElements, THeadRowElement).

  row(_, []).
  row(Element, [Datum | Data]) :-
    create(td, DataElement),
    inner_text(DataElement, Datum),
    append_child(Element, DataElement),
    row(Element, Data).

  fill_table_row([], [], _).
  fill_table_row([Datum | Data], [], ParentElement) :-
    create(th, TDataElement),
    inner_text(TDataElement, Datum),
    append_child(ParentElement, TDataElement),
    fill_table_row(Data, [], ParentElement).
  fill_table_row([Datum | Data], [Element | Elements], ParentElement) :-
    inner_text(Element, Datum),
    fill_table_row(Data, Elements, ParentElement).

  inner_text(Element, Text) :- set_prop(Element, innerText, Text).`;

new P.type.Module(
  "app",
  {
    ...parseProlog(tablePl),
    "prolog_results_table/1": function (thread, point, atom) {
      const el = atom.args[0];
      thread.prepend([
        new P.type.State(
          point.goal.replace(
            new P.type.Term("=", [el, P.fromJavaScript.apply(prologResultsTable)]),
          ),
          point.substitution,
          point,
        ),
      ]);
    },
  },
  ["table_row/1", "table_header/1"],
  {
    dependencies: ["dom", "js"],
  },
);

async function runQuery(rows, query, queryFormElement) {
  const diagsElement = document.getElementById("prolog_diagnostics");
  const diagsHeading = diagsElement.querySelector("h2");
  const diagsElementLastChild = diagsElement.lastElementChild;
  let diagnosticsMessagesElement = document.createElement("p");
  diagnosticsMessagesElement.innerText = "No warnings and no errors.";
  queryFormElement.setCustomValidity("");
  const tableElement = prologResultsTable;

  const facts = [];
  for (const data of rows) {
    const [artists, albumName] = data;
    const artistList = artists.split(", ");

    const fact = new P.type.Term('album', [P.fromJavaScript.apply(artistList), P.fromJavaScript.apply(albumName)]);
    facts.push(fact.toString({quoted: true}) + '.');
  }

  const session = P.create();
  try {
    await session.promiseConsult(':- use_module(library(app)).\n' + facts.join('\n'));
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

  document.getElementById("prolog_results").replaceWith(tableElement);
  prologResultsTable = createPrologResultsTableElement();

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
