import { parse } from "csv-parse/browser/esm";
import {BaseStyles, ThemeProvider, FormControl, Textarea, Button, Stack} from '@primer/react';
import {Table, DataTable} from '@primer/react/experimental';
import {CircleSlashIcon, AlertFillIcon} from '@primer/octicons-react';
import { signal, computed, useComputed, useSignal } from "@preact/signals-react";
import { useSignals } from "@preact/signals-react/runtime";
import { render } from "preact";
import "@primer/primitives/dist/css/primitives.css";
import '@primer/primitives/dist/css/functional/themes/dark.css';
import "./index.css";

const P = globalThis.pl;

const cds = await (await fetch("/assets/my-music-catalog/music-catalog - CDs.csv")).text();
const rows = await new Promise((resolve, reject) => parse(cds, (err, data) => {
  if (err) {
    reject(err);
    return;
  }
  resolve(data);
}));

function prologFormOnSubmit(event) {
  event.preventDefault();
  const form = event.target;
  const queryFormElement = form.elements["prolog_query"];
  const query = queryFormElement.value;
  isUserQuery.value = true;
  runQuery(rows, query);
}

const prologQueryValidationMessage = signal();
const defaultQuery = "album(Artists, Name), table_header(['Artists', 'Album']), table_row([Artists, Name]).";

function PrologForm() {
  useSignals();

  const prologQuery = useSignal(defaultQuery);

  function onPrologFormInput(event) {
    prologQueryValidationMessage.value = null;
    prologQuery.value = event.target.value;
  }

  return (
    <Stack as="form" onSubmit={prologFormOnSubmit}>
      <FormControl>
        <FormControl.Label>Prolog query</FormControl.Label>
        {/* Textarea is controlled so that rerenders due to validation don't clear input. */}
        <Textarea name="prolog_query" block onInput={onPrologFormInput} value={prologQuery.value} style={{"font-family": "var(--fontStack-monospace)"}} />
        {/* I don't use Show because then textarea is not styled for invalid state. */}
        {prologQueryValidationMessage.value && <FormControl.Validation variant="error">{prologQueryValidationMessage.value}</FormControl.Validation>}
      </FormControl>
      <Stack direction="horizontal" align="center">
        <span aria-live={isUserQuery.value ? "polite" : "off"}>
          {isTableDataLoading.value ? "" : "Query finished. Results are shown under the 'Results' heading."}
        </span>
        <Button variant="primary" type="submit" style={{"margin-left": "auto"}}>Submit</Button>
      </Stack>
    </Stack>
  );
}

function PrologResultsTable() {
  useSignals();

  const columns = useComputed(() => tableHeaders.value.map((header, index) => ({ header, field: index.toString() })));

  const data = useComputed(() => tableData.value.map(row => {
    return row.map(datum => {
      if (datum instanceof Array) {
        return datum.join(", ");
      }
      return datum;
    });
  }));

  return (
    <Table.Container>
      {
        isTableDataLoading.value ?
          <Table.Skeleton
            rows={rows.length/2}
            columns={columns.value}
          />
        : <DataTable
            data={data.value}
            columns={columns.value}
          />
      }
    </Table.Container>
  );
}

function parseProlog(rules) {
  const session = P.create();
  session.consult(rules);
  return session.rules;
}

const tableData = signal([]);
const isTableDataLoading = signal(false);
const isUserQuery = signal(false);
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
    "warning_/1": function (thread, point, atom) {
      thread.throw_warning(new P.type.Term("warning", [new P.type.Term("generic", [atom.args[0]])]));
      thread.success(point);
    },
  },
  ["table_row/1", "table_header/1", "warning_/1"],
  {
    dependencies: ["dom", "js"],
  },
);

const diagnostics = signal([]);

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
    await session.promiseConsult(':- use_module(library(app)).\n' + facts.join('\n'));
  } catch (err) {
    console.error('during consult', err.toString());
    throw err;
  }
  for (const warning of session.get_warnings()) {
    console.warn('consult warnings', warning.toString());
  }
  const diagnosticsMessages = [];
  let errorMessage;
  try {
    await session.promiseQuery(query);
  } catch (err) {
    errorMessage = err.toString();
    prologQueryValidationMessage.value = "Invalid Prolog query. Check for syntax errors.";
  }
  pushWarnings();
  if (errorMessage) {
    displayDiagnostics();
    return;
  }

  tableHeaders.value = [];
  tableData.value = [];
  isTableDataLoading.value = true;

  try {
    for await (const answer of session.promiseAnswers()) {
      // warnings are reset every time you ask for another answer
      pushWarnings();
    }
  } catch (err) {
    errorMessage = err.toString();
    // Catch any remaining warnings
    pushWarnings();
  }

  isTableDataLoading.value = false;

  displayDiagnostics();

  function displayDiagnostics() {
    errorMessage && diagnosticsMessages.push({level: 'Error', msg: errorMessage});
    diagnostics.value = diagnosticsMessages;
  }

  function pushWarnings() {
    for (const warning of session.get_warnings()) {
      diagnosticsMessages.push({level: 'Warning', msg: warning.toString()});
    }
  }
}

function Diagnostics() {
  useSignals();

  return (
    <>
      <h3>Warnings and errors</h3>
      {/* TODO: distinguish between warnings and errors */}
      {/* TODO: Announce change to assistive technology? */}
      {diagnostics.value.length
        // not sure what to use as key
        ? <ol>{diagnostics.value.map(m => <li><DiagnosticIcon level={m.level} /> {m.level}: <span style={{"font-family": "var(--fontStack-monospace)"}}>{m.msg}</span></li>)}</ol>
        : <p>No warnings and no errors.</p>}
    </>
  );
}

function DiagnosticIcon({level}) {
  switch (level) {
    case 'Warning':
      return (
        <AlertFillIcon size={16} />
      );
    case 'Error':
      return (
        <CircleSlashIcon size={16} />
      );
      break;
    default:
      console.warn(`Unknown diagnostic level: ${level}`);
      return null;
  }
}

function Root() {
  return (
    <ThemeProvider colorMode="night">
      <BaseStyles>
        <PrologForm />
        <Diagnostics />
        <h3>Results</h3>
        <PrologResultsTable />
      </BaseStyles>
    </ThemeProvider>
  );
}

runQuery(rows, defaultQuery);
render(<Root />, document.getElementById("prolog_preact"));
