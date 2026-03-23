import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['assets/my-music-catalog/index.js'],
  bundle: true,
  outdir: '_site/assets/my-music-catalog/',
  format: 'esm',
  external: ['fs', 'child_process', 'path', 'os', 'crypto']
})
