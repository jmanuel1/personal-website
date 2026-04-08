---
layout: post
title: music
slug: my-music-catalog
extra_css: /assets/my-music-catalog/index.css
---

<!-- TODO: clickbait title -->

I recently decided to start keeping track of what music I own copies of because
I started to have trouble remembering what I haven't bought yet. Additionally, I
was about to move, so I was going to have to look at all my CDs anyway. I wanted
a way to catalog my music using software that is offline and that doesn't have
vendor lock-in.

However, several months ago, I learned about this spreadsheet program called
[Recalc](https://b4er.github.io/recalc/). Recalc is a [*dependently
typed*](https://en.wikipedia.org/wiki/Dependent_type) spreadsheet, which is to
say, its formula language is a small dependently typed language, in which types
can be a function of values, based on
[LambdaPi](https://www.andres-loeh.de/LambdaPi/LambdaPi.pdf). The idea of
getting Recalc to work on the web entertained me, since the Recalc backend is
written in [Haskell](https://www.haskell.org/). Plus, a spreadsheet is an easy
way to keep track of albums, which gave me an excuse to try using Recalc. Thus,
I tried compiling the Recalc backend to JS, then to a WebAssembly System Interface
(WASI) program. Unfortunately, I encountered linker errors that I didn't
understand with [the Glasgow Haskell Compiler
(GHC)'s](https://www.haskell.org/ghc/) JS backend, and I didn't feel like trying
to get the WASM program to accept input asynchronously. I had trouble quickly
understanding the Haskell code, so I decided to move on instead of dealing with
the issues I had with WASM (specifically WASI).

<!-- TODO: improve clickbait using AI -->
<!-- TODO: discuss options I looked at -->
Still, I wanted a spreadsheet/data grid interface with an unusual choice of
query or formula language. Among all the available options, I settled upon a
well-known traditional AI technology. After all, AI is all the rage these days.
The technology I chose is famous, and has a longer history than Large Language
Models. Unlike LLMs, this technology isn't stochastic--it gives you exact and
predictable answers.

Anyway, the technology is called [Prolog](https://en.wikipedia.org/wiki/Prolog).
Enter in a Prolog query in the form below to change what results are displayed.
You can change the headers of the table using the `table_header/1` predicate.
You can add rows to the table using the `table_row/1` predicate. Both of these
predicates are imperative. There is already an example query in the form.

<form id="prolog_form">
<label for="prolog_query" class="width-full mb-1 d-block">
  Prolog query:
</label>
<textarea id="prolog_query" name="prolog_query" class="width-full text-mono">album(Artists, Name), table_header(['Artists', 'Album']), table_row([Artists, Name]).</textarea>
<button type="submit" class="ml-auto d-block mb-1 mt-1">Submit</button>
</form>

<div id="prolog_diagnostics">
  <h2>Warnings and Errors</h2>
  <p>No warnings and no errors.</p>
</div>

<div id="prolog_preact"></div>

<script src="/assets/tau-prolog/modules/core.js"></script>
<script src="/assets/tau-prolog/modules/promises.js"></script>
<script src="/assets/tau-prolog/modules/dom.js"></script>
<script src="/assets/tau-prolog/modules/js.js"></script>
<script type="module" src="/assets/my-music-catalog/index.js"></script>

<!-- TODO: implementation notes -->

## Acknowledgments

- [Tau Prolog license](/assets/tau-prolog/LICENSE.txt)
