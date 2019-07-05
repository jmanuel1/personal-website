Things I did to migrate from Bower to Yarn:

* Added `node_modules` to .gitignore

`bower-away` made things easy by linking `bower-components` to
`node_modules/@bower-components` so I don't have to change my code.

```
C:\Users\Jason\Documents\GitHub\material-search>bower-away
Error: ENOENT: no such file or directory, open 'C:\Users\Jason\Documents\GitHub\material-search\bower_components\prism\.bower.json'
    at Object.fs.openSync (fs.js:646:18)
    at Object.fs.readFileSync (fs.js:551:33)
    at _callee$ (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:99:40)
    at tryCatch (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:62:40)
    at Generator.invoke [as _invoke] (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:296:22)
    at Generator.prototype.(anonymous function) [as next] (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:114:21)
    at step (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:253:30)
    at _next (C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:268:9)
    at C:\Users\Jason\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:275:7
    at new Promise (<anonymous>)
```

Solution: In my case, I got rid of the offending directory, which contained
only empty directories, based on [this `bower-away`
issue](https://github.com/sheerun/bower-away/issues/18).

Link to original article:
https://bower.io/blog/2017/how-to-migrate-away-from-bower/

To get a sense of the magnitude of my dependency tree, some of the output from
`bower list`:

    │ │ │ └─┬ polymer#1.11.3
    │ │ │   └── webcomponentsjs#0.7.24
    │ │ └── polymer#1.11.3
    │ ├─┬ paper-spinner#1.2.1 (latest is 3.0.2)
    │ │ ├─┬ iron-flex-layout#1.3.9
    │ │ │ └── polymer#1.11.3
    │ │ ├─┬ paper-styles#1.3.1
    │ │ │ ├── font-roboto#1.1.0
    │ │ │ ├─┬ iron-flex-layout#1.3.9
    │ │ │ │ └── polymer#1.11.3
    │ │ │ └─┬ polymer#1.11.3
    │ │ │   └── webcomponentsjs#0.7.24
    │ │ └── polymer#1.11.3
    │ ├─┬ paper-styles#1.3.1
    │ │ ├── font-roboto#1.1.0
    │ │ ├─┬ iron-flex-layout#1.3.9
    │ │ │ └── polymer#1.11.3
    │ │ └─┬ polymer#1.11.3
    │ │   └── webcomponentsjs#0.7.24
    │ ├─┬ paper-tabs#1.8.0 (latest is 3.1.0)
    │ │ ├─┬ iron-behaviors#1.0.18
    │ │ │ ├─┬ iron-a11y-keys-behavior#1.1.9
    │ │ │ │ └── polymer#1.11.3
    │ │ │ └── polymer#1.11.3
    │ │ ├─┬ iron-flex-layout#1.3.9
    │ │ │ └── polymer#1.11.3
    │ │ ├─┬ iron-icon#1.0.13
    │ │ │ ├─┬ iron-flex-layout#1.3.9
    │ │ │ │ └── polymer#1.11.3
    │ │ │ ├─┬ iron-meta#1.1.3
    │ │ │ │ └─┬ polymer#1.11.3
    │ │ │ │   └── webcomponentsjs#0.7.24
    │ │ │ └── polymer#1.11.3
    │ │ ├─┬ iron-iconset-svg#1.1.2
    │ │ │ ├─┬ iron-meta#1.1.3
    │ │ │ │ └─┬ polymer#1.11.3
    │ │ │ │   └── webcomponentsjs#0.7.24
    │ │ │ └─┬ polymer#1.11.3
    │ │ │   └── webcomponentsjs#0.7.24
    │ │ ├── iron-menu-behavior#1.3.1 (latest is 3.0.2)
    │ │ ├─┬ iron-resizable-behavior#1.0.6
    │ │ │ └── polymer#1.11.3
    │ │ ├─┬ paper-behaviors#1.0.13
    │ │ │ ├─┬ iron-behaviors#1.0.18
    │ │ │ │ ├─┬ iron-a11y-keys-behavior#1.1.9
