import * as esbuild from 'esbuild';

await esbuild.build({
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
