import * as esbuild from 'esbuild';

const args = process.argv.slice(2);
const watch = args.includes("--watch");

const context = await esbuild.context({
  entryPoints: ['assets/my-music-catalog/index.js'],
  bundle: true,
  outdir: '_site/assets/my-music-catalog/',
  format: 'esm',
  external: ['fs', 'child_process', 'path', 'os', 'crypto']
});

import * as fs from 'node:fs/promises';

await fs.cp('node_modules/tau-prolog/', '_site/assets/tau-prolog/', {
  recursive: true,
});

await fs.rename('_site/assets/tau-prolog/LICENSE', '_site/assets/tau-prolog/LICENSE.txt');

if (watch) {
  context.watch();
  console.log('Started watching for changes...');
} else {
  context.rebuild();
  context.dispose();
}
