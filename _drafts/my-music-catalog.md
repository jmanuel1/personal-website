---
layout: post
title: music
slug: my-music-catalog
---

<form id="prolog_form">
<label for="prolog_query" class="width-full mb-1 d-block">
  Prolog query:
</label>
<textarea id="prolog_query" name="prolog_query" class="width-full text-mono">album(Artists, Name), table([Artists, Name]).</textarea>
<button type="submit" class="ml-auto d-block mb-1 mt-1">Submit</button>
</form>

<table id="prolog_results"></table>

<script src="/assets/tau-prolog/modules/core.js"></script>
<script src="/assets/tau-prolog/modules/promises.js"></script>
<script src="/assets/tau-prolog/modules/dom.js"></script>
<script src="/assets/tau-prolog/modules/js.js"></script>
<script type="module" src="/assets/my-music-catalog/index.js"></script>

## Acknowledgments

- [Tau Prolog license](/assets/tau-prolog/LICENSE.txt)
