import { parse } from "csv-parse/browser/esm";
import {BaseStyles, ThemeProvider} from '@primer/react';
import {Table, DataTable} from '@primer/react/experimental';
import { signal } from "@preact/signals-react";
import { useSignals } from "@preact/signals-react/runtime";
import { render } from "preact";
import '@primer/primitives/dist/css/functional/themes/dark.css';
import "./index.css";

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

function PrologResultsTable() {
  useSignals();

  return (
    <Table.Container>
      <DataTable
        data={tableData.value}
        columns={tableHeaders.value.map((header, index) => ({ header, field: index.toString() }))}
      />
    </Table.Container>
  );
}

function parseProlog(rules) {
  const session = P.create();
  session.consult(rules);
  return session.rules;
}

const tableData = signal([]);
const tableHeaders = signal([]);

new P.type.Module(
  "app",
  {
    "table_row/1": function (thread, point, atom) {
      const row = atom.args[0];
      tableData.value = [...tableData.value, row.toJavaScript()];
      thread.success(point);
    },
    "table_header/1": function (thread, point, atom) {
      tableHeaders.value = atom.args[0].toJavaScript();
      thread.success(point);
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

  tableData.value = [];

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

function Root() {
  return (
    <ThemeProvider colorMode="night">
      <BaseStyles>
        <PrologResultsTable />
      </BaseStyles>
    </ThemeProvider>
  );
}

render(<Root />, document.getElementById("prolog_preact"));
