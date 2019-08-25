---
layout: post
title: The Uses of Selenium
slug: the-uses-of-selenium
date: '2019-08-24 21:11:48-07:00'
---

# The Uses of Selenium

Selenium is a tool that helps you interact with a web browser programmatically.
With Selenium, you can do things like loading a website, simulating clicks, and
automating the filling of forms. The power of Selenium is often used for
automation and cross-browser testing. In the words of the [Selenium
website](https://www.seleniumhq.org):

> *Selenium automates browsers.* ... What you do with that power is entirely up
> to you.

## Automating mundane tasks

Selenium is often used to automate tasks that are repetitive, mundane, and/or
would take too long to do manually. I haven't used Selenium in this way, but
others have. A simple example is [using Selenium with PowerShell to run a Google
search in Google
Chrome](https://tech.mavericksevmont.com/blog/powershell-selenium-automate-web-browser-interactions-part-i/).
Real Python has a [tutorial on using Selenium to track songs you listen to on
bandcamp](https://realpython.com/modern-web-automation-with-python-and-selenium/),
too.

## Testing web front ends

One of the biggest uses of Selenium is to perform integration/system testing of
website front ends. Imagine you're developing a website. After every set of
changes, you click through the site to make sure it still works. This testing
tactic is fine for a simpler site, but as your website increases in complexity,
two pain points will start to show:

- Manually testing many user scenarios is time-consuming.
- Manually testing many user scenarios is error-prone since you may forget to
perform some tests.

Whenever you experience these circumstances due to a manual task, you may have
found an opportunity for automation. Selenium lets you automate much of this
click-and-see-what-happens testing with a programming language of your choosing.

### An example

I have a project called [Material
Search](https://jmanuel1.github.io/material-search/#!/material-search/) that I'm
currently adding automated tests for. If you open up the project, you see that
there's a blue app header with three tabs. (Clicking on the tabs doesn't do
anything). Before, I would test that the tabs exist and have the correct text by
manually checking the page. Now, I use Selenium to perform those tests.

## Learn more

Selenium is a powerful web automation framework that can make your life easier,
whether you need to test your web app or quickly enter lots of data into a web
form. Here's some more information about some of Selenium's applications:

- [6 Easy Steps to Testing Your Chrome Extension With
Selenium](https://www.blazemeter.com/blog/6-easy-steps-testing-your-chrome-extension-selenium)
- [Getting Started with Selenium for Automated Website
Testing](https://wiki.saucelabs.com/display/DOCS/Getting+Started+with+Selenium+for+Automated+Website+Testing)

