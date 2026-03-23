import * as P from "tau-prolog/modules/core";
import promisifyProlog from "tau-prolog/modules/promises";
promisifyProlog(P);
import { parse } from "csv-parse/browser/esm";

const cds = await (await fetch("/assets/my-music-catalog/music-catalog - CDs.csv")).text();
parse(cds, (err, data) => {
  if (err) {
    throw err;
  }
  onParse(data);
});

async function onParse(rows) {
  const facts = [];
  for (const data of rows) {
    const [artists, albumName] = data;
    const artistList = artists.split(", ");

    const fact = new P.type.Term('album', [P.fromJavaScript.apply(artistList), P.fromJavaScript.apply(albumName)]);
    facts.push(fact.toString({quoted: true}) + '.');
  }

  const session = P.create();
  try {
    await session.promiseConsult(facts.join('\n'));
  } catch (err) {
    console.error('during consult', err.toString());
    throw err;
  }
  await session.promiseQuery("album(Artists, Name).");
  for await (const answer of session.promiseAnswers()) {
    console.log(session.format_answer(answer));
  }
}
