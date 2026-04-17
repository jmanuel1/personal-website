import * as esbuild from 'esbuild';
import esbuildPluginLicense from 'esbuild-plugin-license';

const args = process.argv.slice(2);
const watch = args.includes("--watch");

const licensePluginOptions = {
  banner: `/*! <%= pkg.name %> v<%= pkg.version %> | <%= pkg.license %> */`,
  thirdParty: {
    includePrivate: false,
    output: {
      file: 'dependencies.txt',
      // Template function that can be defined to customize report output
      template(dependencies) {
        return dependencies.map((dependency) => `${dependency.packageJson.name}:${dependency.packageJson.version} -- ${dependency.packageJson.license}\n${dependency.licenseText}`).join('\n');
      },
    }
  }
};

const context = await esbuild.context({
  entryPoints: ['assets/my-music-catalog/index.jsx'],
  bundle: true,
  outdir: '_site/assets/my-music-catalog/',
  format: 'esm',
  alias: {
    'react': 'preact/compat',
    'react-dom': 'preact/compat',
  },
  jsxFactory: 'h',         // Use Preact's h function
  jsxFragment: 'Fragment', // Use Preact's Fragment
  inject: ['./preact-shim.js'], // Optional: avoid importing 'h' in every file
  sourcemap: true,
  plugins: [esbuildPluginLicense(licensePluginOptions)],
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
