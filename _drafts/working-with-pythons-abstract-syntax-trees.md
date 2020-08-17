---
layout: post
title: Working with Python's Abstract Syntax Trees
slug: working-with-pythons-abstract-syntax-trees
---

Python is a dynamic language with a large and varied standard library. You can
even use Python to manipulate other Python programs! That's called
[*metaprogramming*](https://en.wikipedia.org/wiki/Metaprogramming), and it's
what we're going to do using Python's `ast` module. By the end of this post,
we'll have implemented [constant
folding](https://en.wikipedia.org/wiki/Constant_folding) for Python. By the way,
I'll be assuming you know some basic Python, but the concepts here should apply
elsewhere.

## AST? What's that?

AST is short for [*abstract syntax
tree*](https://en.wikipedia.org/wiki/Abstract_syntax_tree). It is a type of
[*tree*](https://en.wikipedia.org/wiki/Tree_%28data_structure%29) that stores
the structure of a program, ignoring details like commas and grouping
parentheses. Here's an example of an AST:

<svg
  id='hello-world-ast'
  data-ast='{"body": [{"value": {"func": {"id": "print", "ctx": {"__type__": "Load"}, "__type__": "Name"}, "args": [{"s": "hello world", "__type__": "Str"}], "keywords": [], "__type__": "Call"}, "__type__": "Expr"}], "__type__": "Module"}'>
</svg>

This AST can be textually represented as
`Module(body=[Expr(value=Call(func=Name(id='print', ctx=Load()),
args=[Str(s='hello world')], keywords=[]))])`. It represents the following
Python code:

```python
print('hello world')
```

Let's go through the structure of this AST. The `Module` within the AST
represents the entire module (which is most often a file). It contains an
expression statement (`Expr`) which contains a function call (`Call`). The
function being called is `Name`d `print`. The function is given only the string
represented by the `Str` node as an argument.

### Brief overview of trees

## How the Python ast module works

## Example: constant folding

## Conclusion/try yourself


<!-- Scripts for displaying ASTs -->
<script>
  function drawTree(astJSON, plot) {
    const ast = JSON.parse(astJSON);
    const g = plot.append("g");
    const root = d3.hierarchy(ast, d => {
      const children = [];
      for (let field in d) {
        if (d[field].__type__ || d[field] instanceof Array)
          children.push(d[field]);
      }
      return children;
    });
    const svgElement = document.querySelector('#hello-world-ast');
    const nodeSize = 24;
    const tree = d3.tree().size([svgElement.clientWidth - nodeSize, svgElement.clientHeight - nodeSize])(root);
    console.debug(root.descendants());
    const node = g.selectAll("rect").data(root.descendants()).enter().append("rect").attr("stroke", "#ffffff").attr("stroke-width", 4).attr("x", d => d.x).attr("y", d => d.y).attr("width", 24).attr("height", 24);
  }
  const svg = d3.select("#hello-world-ast");
  const plot = svg.append("g");
  drawTree(svg.attr("data-ast"), plot);
</script>
