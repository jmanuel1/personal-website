---
start_date: 5/11/2019
title: "Migrating from Bower to Yarn"
---

Migrating from Bower to Yarn
============================

I've started updating one of my side projects from a few years ago. It's called
[Material Search](https://github.com/jmanuel1/material-search). It's a
prototype of what a material design search page could look like. I started the
project in 2015 and based it on the [Polymer Starter
Kit](https://github.com/Polymer/polymer-starter-kit). A lot has changed between
2015 and 2019, like the package manager Bower, which I used for Material
Search, becoming
[deprecated](https://devblogs.microsoft.com/aspnet/what-happened-to-bower/).

In this post, I'm going to describe how I migrated Material Search from Bower to
another package manager called Yarn. Migration can be done by resolving all of
the dependencies of your project and adding them flattened to your new
`package.json` (the package manifest that Yarn uses). Doing this manually could
be tedious. For example, here's part of the dependency tree for Material Search,
as output by `bower list`:

```
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
```

As you can tell, it could be quite a bit of work to do all the migration
yourself.

Using a tool called [`bower-away`](https://github.com/sheerun/bower-away), it
won't be difficult. `bower-away` makes things easier by linking the
`bower_components` directory to `node_modules/@bower_components/`, where your
packages will soon reside, so that your code doesn't break.

I'm going to assume you have `npm`, Bower, and Yarn already installed and in
your path, and that you have a Bower package/project ready to migrate.

Step 1: Installing `bower-away`
-------------------------------

First, let's install `bower-away` globally using `yarn` or `npm`:

```console
project-dir> npm i -g bower-away
```

or

```console
project-dir> yarn global add bower-away
```

Step 2: The Migration Process
-----------------------------

In the root of your project (wherever your `bower.json`, the Bower package
manifest, is located), run `bower-away`:

```console
project-dir> bower-away
```

The first time you run `bower-away`, you might get an error similar to this:

```
Error: ENOENT: no such file or directory, open '...\material-search\bower_components\prism\.bower.json'
    at Object.fs.openSync (fs.js:646:18)
    at Object.fs.readFileSync (fs.js:551:33)
    at _callee$ (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:99:40)
    at tryCatch (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:62:40)
    at Generator.invoke [as _invoke] (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:296:22)
    at Generator.prototype.(anonymous function) [as next] (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\node_modules\regenerator-runtime\runtime.js:114:21)
    at step (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:253:30)
    at _next (...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:268:9)
    at ...\AppData\Roaming\nvm\v8.11.3\node_modules\bower-away\cli.js:275:7
    at new Promise (<anonymous>)
```

In my case, the offending directory
(`...\material-search\bower_components\prism\`) contained only empty folders,
so I simply deleted it. Somebody had a [similar
issue](https://github.com/sheerun/bower-away/issues/18) and it was suggested
that the directory shouldn't be there.

Now, the tool should do some of its work, print further instructions, and then
terminate. Do whatever it says, including when it tells you to run `bower-away`
again. Make sure to reinstall your packages with Yarn and not NPM. In my
experience, NPM can't handle the version tags for some reason. If you're using
Git, I suggest adding `node_modules/` to your `.gitignore` once your Bower
packages are installed with Yarn.

Step 3: Nearing the End
-----------------------

The last time you run `bower-away`, you should get a message like this:

```
Your project is now converted to Yarn! Thank you for using Bower!

You should find all bower components in node_modules/@bower_components

The postinstall script should also link it to old location of components

It is advisable to remove postinstall script and point your tools
to point to node_modules/@bower_components instead, though.

You may also consider creating separate directory for front-end project with separate package.json
```

You can follow `bower-away`'s suggestions if you want, but you're done! If you
want to learn more about `bower-away` and migration to Yarn, read the [original
tutorial on how to migrate away from
Bower](https://bower.io/blog/2017/how-to-migrate-away-from-bower/).
