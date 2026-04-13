---
layout: post
title: Using "AI Technology" to Keep Track of My Music Collection
slug: my-music-catalog
extra_css: /assets/my-music-catalog/index.css
---

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

<!-- TODO: improve flow of clickbait -->
<!-- TODO: discuss options I looked at -->
Still, I wanted a spreadsheet/data grid interface with an unusual choice of
query or formula language. Among all the available options, I settled upon a
well-known traditional AI technology. After all, AI is all the rage these days.
The technology I chose is famous, and has a longer history than Large Language
Models. Unlike LLMs, this technology isn't stochastic--it gives you exact and
predictable answers. Imagine if instead of telling AI how to do something, you
just told it what’s true—and it figured the rest out like some kind of
logic-obsessed detective. Before tools like ChatGPT and companies like OpenAI
made “AI” synonymous with giant neural networks and GPUs on fire, this tool was
already doing something wild: thinking in pure logic.

While modern AI slurps billions of data points, the language I chose just sits
there like:

> Give me rules. Give me facts. I’ll handle the truth.

You don’t write step-by-step instructions. You declare things like:

- Socrates is human
- All humans are mortal

And the language goes: “Cool, Socrates is mortal. Next question?”

In today’s AI hype cycle—full of buzzwords like “reasoning,” “agents,” and
“chain-of-thought"--this tool is basically:

- Explainable AI before it was cool (every conclusion has a traceable logic
  path)
- Symbolic reasoning on steroids (no black-box mystery)
- Deterministic, not probabilistic (it’s either true or false, no vibes)

It’s like the anti-LLM. Indeed, this 1970s programming language might understand
logic better than your favorite AI model. Not because it’s smarter overall—but
because it was built for something today’s AI is still struggling to master:
actual, consistent reasoning instead of just very convincing guessing.

Anyway, the technology is called [Prolog](https://en.wikipedia.org/wiki/Prolog).
(The above Prolog clickbait was written with the assistance of ChatGPT.)

## How to browse my collection

<!-- TODO: album predicate -->

Enter a Prolog query into the form below to change which results are displayed.
You can change the headers of the table using the `table_header/1` predicate.
You can add rows to the table using the `table_row/1` predicate. Both of these
predicates are imperative. There is already an example query in the form.

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
