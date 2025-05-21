---
layout: post
title: Revisiting Just BASIC
slug: revisiting-just-basic
# date: '2020-07-21 16:20:53-07:00'
# last_modified_at: '2020-08-23 22:36:00-07:00'
---

Just BASIC is a freeware product providing a programming language and IDE for
building Windows programs. It's developed by [Shoptalk
Systems](https://justbasic.com/aboutus.html). It's the first programming
language I learned, back around 2011. I found it in a Google Search ad. Before
that, I had no idea what programming was, let alone did I consider it a career
choice. As far as I was concerned, I was going to become an astronomer. It comes
with a tutorial that I went through--I was more patient with tutorials back
then. The first time that I felt the rush of getting a program to work was when
I wrote my first Hello World ever in Just BASIC. Well, I think that happened--it
was a long time ago. The first game that I wrote is the high-or-low game from
the language's tutorial.

Recently, I decided to revisit Just BASIC to see how it's changed. Just BASIC is
still actively developed. In fact, version 2.0 was released in November 2022. As a child, I
used version 1, which I learned is still hosted on [the Just BASIC
website](https://justbasic.com/jbwin101.exe) after finding the filename of the
installer on
[software.informer](https://just-basic.software.informer.com/download/), a
website that I've never heard of.

Since I didn't have copies of the BASIC programs I wrote a decade ago readily
available, I looked up example Just BASIC code on GitHub. Then, I installed Just
BASIC on to an external drive and fired it up. Upon starting Just BASIC, I'm
greeted with a dialog that links to some resources, including the tutorial.

![Just BASIC upon first start up, with links to a tutorial and other
resources](/assets/revisiting-just-basic/just-basic-start.png)

The UI looks very recognizable. Clicking on "Tutorial" takes me to a local web
page, which used to be a [Windows .hlp
file](https://support.microsoft.com/en-us/topic/error-opening-help-in-windows-based-programs-feature-not-included-or-help-not-supported-3c841463-d67c-6062-0ee7-1a149da3973b).
The Windows Help format (WinHlp32) is a way of packaging documentation for
Windows programs that isn't supported by modern Windows versions. Based on the
Just BASIC help page titled "Help Files are Converted to HTML," I think the
documentation was converted to HTML when Windows Vista still had some support
from Microsoft.

![The table of contents of the Just BASIC tutorial, which is organized into
weeks](/assets/revisiting-just-basic/tutorial-toc.png)

A part of the tutorial that I recognize is the high-or-low game in `HILO.BAS`.
It looks like the language hasn't changed much syntactically. You even have to
append a dollar sign to end of the name of any variable that contains strings!
(See the Variables chapter in the Help.) Somehow, I remember one of the first
pages of the tutorial asking you to enter `print "Hello World!"` as my first
program, but I don't see that at the beginning of the tutorial. So, I downloaded
Just BASIC 1.01, viewed its tutorial using [a copy of
WinHlp32.exe](https://raxsoft.com/raxccm/software_mirrors.php?pid=1&progid=13),
and it doesn't start with Hello World either. I guess I made up that memory.

Something else I noticed from both versions of the tutorial is that they are
geared towards business use cases. Maybe the version 2 tutorial is more
business-oriented than version 1, but the last time I looked at it before
writing this post, it was about 2012.

Just BASIC comes with a form designer written in Just BASIC. You can access the
designer through the Run menu with the "FreeForm GUI editor" option.

![The FreeForm GUI editor item in the Run
menu](/assets/revisiting-just-basic/free-form-gui-run-menu.png)

The GUI editor looks like how I remember it: an inner window with a toolbox on
the left, all in an older Windows style. I don't remember what the tool icons
mean, and I doubt I ever understood all of them. Since there are no tooltips
either, I started clicking on the tools that piqued my interest. The first two
buttons are for loading and saving form designs, respectively.

![The load (first) and save (second) buttons in the GUI editor
toolbox](/assets/revisiting-just-basic/load-and-save-form.jpg)

The two buttons in the second row from the bottom export whatever form you've
designed in the GUI as code. I'm not sure what the difference between them is.

![Two buttons at the bottom of the GUI editor toolbox for exporting a form as
code](/assets/revisiting-just-basic/export-form.jpg)

Let's run a program I found online. This one's called "When Chickens Attack!!!,"
and it's creator is Bennett Cyphers. You can find it on
[GitHub](https://github.com/bcyphers/justBASIC). It seems to work without
modification, so I suppose Shoptalk Systems maintained some level compatibility
between versions 1 and 2.

As I look at the code, there are some oddities about the language that I didn't
notice before. I didn't notice these when I first used the language, since it is
my first language, but some parts of Just BASIC syntax are different from every
other programming language I've used. I suppose some of these idiosyncrasies are
normal compared to Just BASIC's related BASIC dialects.

The first thing I notice is that a Just BASIC program communicates with windows
and controls by *printing* messages to them. Indeed, you give the control name
as a target to the print statement along with a string containing a command to
send to the control. For example, here's a program that creates a graphics
window titled "Hello World!" and fills it with yellow:

```basic
open "Hello World!" for graphics as #g
print #g, "fill yellow"
wait
```

In this example, I print the message "fill yellow" to the window #g to fill it
with yellow.

To create controls, there are commands for each kind of control you can create.
For example, the `textbox` keyword is used to create a textbox in a window, as
in `textbox #windowname.textboxname, 10, 30, 100, 20`. Those numbers at the end
are the x and y coordinates of the textbox and its width and height,
respectively. There's no other programming language I've used where the way to
create GUI controls is through particular syntax allocated to those controls.

Another thing is that there are three ways to define procedures. There are
"functions" which are different from "subroutines" and that have a different
call syntax. The third way is to define a label, and then use the `gosub`
statement to jump to that label. Version 1 of the tutorial doesn't seem to teach
you explicitly how to define your own functions and subroutines, but I see uses
of `gosub` in the tutorial's homework solutions. That would explain I remember
using `gosub` and labels, but not the function nor the subroutine syntax. Oddly,
the version 2 tutorial introduces function or subroutine definitions either.

## Personal Archeology

While writing this post, I remembered that I once printed out the source of a
BASIC program during middle school, and that my parents might be able to find it
in their house. They found two versions, text-mode and GUI, of a program that
distributes days among months in a hypothetical calendar given the length of the
year, the length of the day, the number of months in a year, and the days per
week. If I remember correctly, the goal of the program is to generate imaginary
calendars for various planets. Here's a [scan of the code with output for an
Earth-like calendar](/assets/revisiting-just-basic/calendar-basic-ocr.pdf),
which is hopefully in order, and here's [the code for a GUI version of the
program](/assets/revisiting-just-basic/calendar-gui.bas). Amazingly, this code
also runs in Just BASIC v2 depsite being writen for version 1. It has a few
bugs, and for some reason I use a string as an array of words.

<!-- TODO: Conclude somehow -->
