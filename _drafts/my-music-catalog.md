---
layout: post
title: music
slug: my-music-catalog
---

<form id="prolog_form">
<label>
  Prolog query:
  <textarea name="prolog_query">album(Artists, Name), table([Artists, Name]).</textarea>
</label>
<button type="submit">Submit</button>
</form>

<table id="prolog_results"></table>

<script src="/assets/tau-prolog/modules/core.js"></script>
<script src="/assets/tau-prolog/modules/promises.js"></script>
<script src="/assets/tau-prolog/modules/dom.js"></script>
<script src="/assets/tau-prolog/modules/js.js"></script>
<script type="module" src="/assets/my-music-catalog/index.js"></script>

## Acknowledgments

- [Tau Prolog license](/assets/tau-prolog/LICENSE.txt)
