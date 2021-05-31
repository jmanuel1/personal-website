---
layout: post
title: Working with Python's Abstract Syntax Trees
slug: working-with-pythons-abstract-syntax-trees
---

<!-- TODO: Make code available, through generation if that's easy -->

<!-- QUESTION: Correct definition of metaprogramming? -->

Python is a dynamic language with a large and varied standard library. You can
even use Python to manipulate other Python programs! That's called
[*metaprogramming*](https://en.wikipedia.org/wiki/Metaprogramming), and it's
what we're going to do using Python's `ast` module. By the end of this post,
we'll have implemented [constant
folding](https://en.wikipedia.org/wiki/Constant_folding) for Python. Constant
folding, stated simply, is the evaluation of expressions containing constants by
a compiler or interpreter before your program actually runs. (I think CPython
already does some constant folding, but that won't stop us.)

By the way, I'll be assuming you know some intermediate Python, but the concepts
here should apply elsewhere. I'll also assume you're using CPython 3.7. If you
don't know what Python implementation you're using, you're probably using
CPython.

## AST? What's that?

AST is short for [*abstract syntax
tree*](https://en.wikipedia.org/wiki/Abstract_syntax_tree). It is a type of
[*tree*](https://en.wikipedia.org/wiki/Tree_%28data_structure%29) that stores
the structure of a program, ignoring details like commas and grouping
parentheses.

<details>
  <summary>Wait! What's a tree?</summary>

  A tree is a recursive data structure that is used to express hierarchical or
  nested information. For example, you could use a tree to represent your family
  tree, a decision tree, regions in your country at various levels from city to
  country, or an organizational chart. A tree is composed of nodes, which are
  cells that can hold data. The nodes are connected by edges which indicate
  parent-child relationships. Here are some resources about trees:

  <ul>
    <li>
      <a href="https://en.wikipedia.org/wiki/Tree_%28data_structure%29">
        Wikipedia article on trees
      </a>
    </li>
    <li>
      <a href="https://medium.com/basecs/how-to-not-be-stumped-by-trees-5f36208f68a7">
        How To Not Be Stumped By Trees
      </a>
    </li>
    <li>
      <a href="https://www.codenewbie.org/basecs/13">
        Podcast version of "How To Not Be Stumped By Trees"
      </a>
    </li>
  </ul>
</details>

Here's an example of an AST:

<!-- TODO: alt -->
<img
  src="/assets/working-with-pythons-abstract-syntax-trees/hello-world-ast.svg"
  width="100%" class="p-4" style="background: white">

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

## How the Python `ast` module works

Python's built-in `ast` module allows us to parse Python code at runtime and get
back ASTs. It also provides functions to help us process these ASTs.

Let's get an AST for the code `print('hello world')`.

```python
import ast

syntax_tree = ast.parse("print('hello world')")
```

By default, `ast.parse` parses code as if it's in its own module. The function
can parse in other modes, but we won't cover those here.

We can get a view of what's in the AST by calling `ast.dump` on it:

```python
print(ast.dump(syntax_tree))
```

This will print:

<!-- hide -->
```python
Module(body=[Expr(value=Call(func=Name(id='print', ctx=Load()), args=[Str(s='hello world')], keywords=[]))])
```

This is the same AST we saw earlier.

Now, let's try executing the code represented by this AST. Python makes this
easy for us; we can first compile the AST into a bytecode object using
`compile`, and then execute that object using `exec`.

```python
exec(compile(syntax_tree, '<string>', 'exec'))
```

After running `exec`, "hello world" should be printed out.

<!-- TODO: Might need to explore traversal -->

## Example: constant folding

## Conclusion/try yourself


