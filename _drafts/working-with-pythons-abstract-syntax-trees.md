---
layout: post
title: Working with Python's Abstract Syntax Trees
slug: working-with-pythons-abstract-syntax-trees
literate: true
---

Python is a dynamic language with a large and varied standard library. You can
even use Python to manipulate Python programs as data! That's called
[*metaprogramming*](https://en.wikipedia.org/wiki/Metaprogramming), and it's
what we're going to do using Python's `ast` module. By the end of this post,
we'll have implemented [constant
folding](https://en.wikipedia.org/wiki/Constant_folding) for Python. Constant
folding, stated simply, is the evaluation of constant expressions by a compiler
or interpreter before your program actually runs. (I think CPython already does
some constant folding, but that won't stop us.)

[The code in this tutorial can be found here.](./code.py)

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

## Example: constant folding

We're going to figure out how to some do basic constant expression evaluation.
We'll handle the following cases:

* Adding numeric and string literals (for example, `2 + 2` and
  `'hello ' + 'dave'`)
* Multiplying numeric literals and list/tuple/strings containing only literals
  (for example, `2.0 * 3.0`, `'abc' * 8`, and `[1, 3, 5] * 0`)

There are many cases we could handle, but we have to start somewhere. I suggest
you create a new file for the program we're about to write.

We'll take some Python code from standard input.

```python
code = input()
```

Then we'll parse the code, store the resulting AST, and print out the AST.

```python
syntax_tree = ast.parse(code)
print(ast.dump(syntax_tree))
```

Now, we need to recursively run a constant folding algorithm through the nodes
of the AST. In other words, we need to *traverse* the AST. We can use the
[`ast.NodeTransformer`](https://docs.python.org/3.7/library/ast.html?highlight=nodetransformer#ast.NodeTransformer)
class to change an AST while traversing it recursively from the top down. To use
`NodeTransformer`, we'll subclass it.

```python
class ConstantFolder(ast.NodeTransformer):
```

Next, we'll override methods like `visit_Str` so that we can perform different
actions depending on the type of node we encounter. For example, the `visit_Str`
method is called when the node transformer sees a `Str` node. The transformer
uses the return value of each `visit_*` method to replace the nodes in the AST,
modifying the structure in-place.

Let's write our transformer code organized to the kinds of expression we want to
evaluate.

### Adding numeric and string literals

The type of AST node that represents addition is `BinOp` where the node's `op`
field is an `Add` instance. Thus, we'll override `visit_BinOp` and check that
the operation is addition.

Since constant folding is recursive, we should first call `visit` on the `left`
and `right` fields of the current node. (This implies a [depth-first
traversal](https://en.wikipedia.org/wiki/Depth-first_search) of the AST.)

```python
    def visit_BinOp(self, node):
        left = self.visit(node.left)
        right = self.visit(node.right)
        # addition case
        if isinstance(node.op, ast.Add):
```

If both `left` and `right` are instances of `ast.Num`, we return a new `ast.Num`
node that contains the sum of the two numbers.

```python
            if isinstance(left, ast.Num) and isinstance(right, ast.Num):
                return ast.Num(left.n + right.n)
```

If both `left` and `right` are instances of `ast.Str`, we return a new `ast.Str`
node that contains the concatenation of the two strings.

```python
            if isinstance(left, ast.Str) and isinstance(right, ast.Str):
                return ast.Str(left.s + right.s)
```

Otherwise, we should return another `BinOp` node with an `Add` as the operator.

```python
            return ast.BinOp(left, ast.Add(), right)
```

### Multiplying numeric literals and list/tuple/strings containing only literals

The type of AST node that represents multiplication is `BinOp` where the node's
`op` field is an `Mult` instance. So let's add another case to our if statement
to handle multiplication.

```python
        elif isinstance(node.op, ast.Mult):
```

First, let's give a name to the AST node types that describe lists and tuples.
We can call them `sequence_node_types`. This value will come in handy later.

```python
            sequence_node_types = (ast.List, ast.Tuple)
```

Now, we'll handle multiplying numeric literals. This is very similar to what we
did for adding numbers.

```python
            if isinstance(left, ast.Num) and isinstance(right, ast.Num):
                return ast.Num(left.n * right.n)
```

Next, we'll handle multiplying a string by a number. We will check that the
number is a non-negative integer. We also need to allow the string and integer
to appear in any order.

```python
            elif isinstance(left, ast.Num) and isinstance(right, ast.Str) and isinstance(left.n, int) and left.n >= 0:
                return ast.Str(left.n * right.s)
            elif isinstance(left, ast.Str) and isinstance(right, ast.Num) and isinstance(right.n, int) and right.n >= 0:
                return ast.Str(left.s * right.n)
```

The third kind of multiplication we want to handle involves lists and tuples. We
can start by checking that one of the operands is a list or tuple display, that
the list or tuple contains only literals, and that the other operand is a
positive integer literal. To check that a list or tuple node contains only
literal nodes, we use a `contains_only_literals` function that we define later.

```python
            elif isinstance(left, ast.Num) and isinstance(right, sequence_node_types) and contains_only_literals(right) and isinstance(left.n, int) and left.n >= 0:
                return type(right)(left.n * right.elts, ast.Load())
            elif isinstance(left, sequence_node_types) and contains_only_literals(left) and isinstance(right, ast.Num) and isinstance(right.n, int) and right.n >= 0:
                return type(left)(left.elts * right.n, ast.Load())
```

In other cases, we can return a `BinOp` node that represents the multiplication
of `left` and `right`.

```python
            else:
                return ast.BinOp(left, ast.Mult, right)
```

### Handling other `BinOp` nodes

To account for other `BinOp` nodes that didn't fit into any of the cases above,
we have an `else` block that returns a `BinOp` node with the same operation type
as the original node and `left` and `right` as operands.

```python
        else:
            return ast.BinOp(left, node.op, right)
```

### Loose end: the `contains_only_literals` function

Earlier, we used a helper function called `contains_only_literals` to tell if a
`List` or `Tuple` node contained only AST nodes for literals in its elements.
Now, we define it.

```python
def contains_only_literals(sequence_ast):
```

We retrieve the elements of the `sequence_ast` node through its `elts`
attribute.

```python
    elements = sequence_ast.elts
```

And, let's say that a 'literal' is either a `Num`, `Str`, or `Bytes`.

```python
    literal_types = (ast.Num, ast.Str, ast.Bytes)
```

Finally, we check if each node in `elements` is an instance of one of the
`literal_types`, and return `True` if that's the case.

```python
    return all(isinstance(element, literal_types) for element in elements)
```

### Trying our `ConstantFolder`

<!-- FIXME: I assumed this would come from stdin above -->
Let's try to constant-fold the expression `'success' * (1 + 1 + (1 * 2) + 1)`.
We can do this by first parsing this expression to get an AST.

```python
syntax_tree = ast.parse("'success' * (1 + 1 + (1 * 2) + 1)")
```

Next, we can use the `visit` method (which is inherited from `ast.NodeVisitor`)
of our `ConstantFolder` class to get the folded AST.

```python
folded_syntax_tree = ConstantFolder().visit(syntax_tree)
```

Now, we can dump the value of `folded_syntax_tree` and see the constant
expression has been evaluated!

```python
print('after folding:')
print(ast.dump(folded_syntax_tree))
```

The output should look like this:

<!-- hide -->
```python
Module(body=[Expr(value=Str(s='successsuccesssuccesssuccesssuccess'))])
```

Here's a graphical depiction of this AST:

![A Module with a body containing only a single Expression node, which contains
the String node with the value "success" repeated five
times.](/assets/working-with-pythons-abstract-syntax-trees/folded-success.svg)

## Conclusion

We've just successfully used Python abstract syntax trees to implement constant
folding ourselves. We went over concepts like what abstract syntax trees are,
how to traverse and modify them, and some of the node types in Python ASTs.

## Try yourself

I encourage going deeper into this topic. Here are some things you can try:

* Constant-folding the subtraction and division of numeric literals (for
  example, `6 - 6`, `1 - 2j`, and `0.0 - -1`)
* Generating interesting visualizations of Python code from ASTs
  * Philippe Ombredanne's
    [Python AST visualizer](https://github.com/pombredanne/python-ast-visualizer)
    might be a good starting point
* Parse Python code to compute intersting statistics about the code
  * Cyclomatic complexity and number of lines per function, for example
* Write a simple type checker for Python, or explore other properties of
  programs you can compute
