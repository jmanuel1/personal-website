---
layout: post
title: Working with Python's Abstract Syntax Trees
slug: working-with-pythons-abstract-syntax-trees
---

# Introduction

Python is a dynamic language with a large and varied standard library. You can
even use Python to manipulate other Python programs! That's called
[*metaprogramming*](https://en.wikipedia.org/wiki/Metaprogramming), and it's what we're going to do using Python's `ast` module.
By the end of this post, we'll have implemented [constant
folding](https://en.wikipedia.org/wiki/Constant_folding) for Python. By the way,
I'll be assuming you know some basic Python, but the concepts here should apply
elsewhere.
