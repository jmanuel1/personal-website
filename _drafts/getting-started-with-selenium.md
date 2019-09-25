---
layout: post
title: Getting Started with Selenium
slug: getting-started-with-selenium
---

<!-- TODO: Introduce article -->
<!-- NOTE: assumed use of Chrome -->

## What is Selenium?

Selenium is a web automation tool. You can use Selenium to programmatically
interact with an Internet browser. That means that you can write code using
[Selenium WebDriver](https://www.seleniumhq.org/projects/webdriver/) or record
browser interactions with [Selenium
IDE](https://www.seleniumhq.org/selenium-ide/) and use the resulting program to
control a browser without human intervention.

I won't go into possible uses for Selenium in this post. If you're interested in
that, you can visit [the Selenium homepage](https://www.seleniumhq.org) or a
[previous post of mine]({% post_url 2019-08-24-the-uses-of-selenium %}).

## Downloading Selenium

<!-- QUESTION: Do we need this step? -->
Go to [Selenium's download page](https://www.seleniumhq.org/download/). You'll
want to download the Selenium Standalone Server. Save the jar file you get to a
directory called `se-get-started`.

For Selenium to be useful, we'll need a *web driver*. Selenium uses this program
to interface with a web browser and control it. For our purposes, we'll download
the Google Chrome web driver from the [ChromeDriver download
page](https://sites.google.com/a/chromium.org/chromedriver/downloads) into the
`se-get-started` directory. Make sure you name it `chromedriver`!

## Creating a web page to test

We're going to use Selenium to test a web page, so let's create a simple example
page. Type the following into a new file called `index.html` and save it in the
`se-get-started` folder.

```html
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Example page</title>
  </head>
  <body>
    Test that this text is here!
  </body>
</html>
```

## Writing a test (in Python)

To prepare our Python environment for writing tests, we first need to install
the Selenium package for Python. We can do that by running

```shell
> pip install selenium
```

on the command line.

Time to write your first test! Create a new file in our `se-get-started` folder;
let's call it `test.py`. We're going to write a Python script that tests whether
or not text appears on our web page.

In our test script, we'll first import a few things from the Selenium package.

```python
import selenium.webdriver as webdriver
import selenium.webdriver.support.ui as ui
import selenium.webdriver.support.expected_conditions as expects
from selenium.webdriver.common.by import By
```

Next, we'll give our script access to the Chrome web driver so that we can
interact with the browser.

```python
driver = webdriver.Chrome('./chromedriver')
```

Before we can test our page, we must load it in the browser. We'll start a web
server on localhost later, so we'll load `http://localhost:8000`.

```python
driver.get('http://localhost:8000')
```

### Waiting for page loads

Since we don't know when the page will complete loading, we'll have to make our
script wait. Specifically, we'll wait for the text in the body of our page to be
visible. To do this, we'll create a function called `wait_for_element_has_text`
that takes the tag name of an element, a web driver object, and the text we want
to wait for.

```python
def wait_for_element_has_text(element, driver, text):
```

In this function, we'll create an object that represents the maximum amount of
time we're willing to wait. This is called a *timeout*. We'll choose 10 seconds
for our timeout.

```python
    wait = ui.WebDriverWait(driver, 10)
```

Next, we need a way to tell Selenium how to find an element. We do this by
creating a tuple which says we should use CSS selectors to find the element
(`By.CSS_SELECTOR`) and contains the selector we want to use (`element`).

```python
    selector = (By.CSS_SELECTOR, element)
```

Now, we need an object that represents what we are waiting for and expecting to
happen in the web browser: there should be visible text in our chosen element.
We can do that using `expects.text_to_be_present_in_element`.

```python
    expectation = expects.text_to_be_present_in_element(selector, text)
```

Finally, we'll tell Selenium to wait for our expectation to be fulfilled, or for
the 10-second timeout to expire (whichever comes first).

```python
    wait.until(expectation)
```

### The test itself

After writing that function, we can use it to wait for the correct text to
appear in the body of our page.

```python
text = 'Test that this text is here!'
wait_for_element_has_text('body', driver, text)
```

Lastly, we'll assert that the text we expect in the body element is there.

```python
body = driver.find_element_by_tag_name('body')
assert body.text == text
```

Now that we've written our test, we can try running it.

## Running the test

## Next steps
