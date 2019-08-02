# So now I'm using Selenium (+ Python) for sytem-level testing of Material Search.

- https://gist.github.com/ChadKillingsworth/d4cb3d30b9d7fbc3fd0af93c2a133a53
  (End-to-end Testing with Shadow DOM) -- **Not directly about Selenium**
- https://www.blazemeter.com/blog/6-easy-steps-testing-your-chrome-extension-selenium

# Installation involves downloading the Selenium .jar, a driver, and installing the Python bindings.

- https://wiki.saucelabs.com/display/DOCS/Getting+Started+with+Selenium+for+Automated+Website+Testing

# It's hard to discover the the API of the Python bindings. I should collect links to docs.

- https://www.seleniumeasy.com/selenium-tutorials/webdriver-methods
- https://seleniumhq.github.io/selenium/docs/api/java/org/openqa/selenium/WebDriver.html

# I wait for an element to be visible in each test.

- https://seleniumhq.github.io/selenium/docs/api/py/webdriver_support/selenium.webdriver.support.expected_conditions.html
- https://docs.seleniumhq.org/docs/04_webdriver_advanced.jsp#explicit-and-implicit-waits
- https://stackoverflow.com/questions/7781792/selenium-waitforelement
- https://www.quora.com/How-would-we-make-sure-that-a-page-is-loaded-using-Selenium-and-WebDriver

# Other

I'm testing so that I know if my code is breaking when I upgrade to Polymer 3.

There are no Selenium type stubs. Or pytest type stubs (I'm using pytest).

I've made a gulp script to automate testing.

Trouble typing into an iron-input: exception "element is not interactable" from
.send_keys().

## On pytest

- http://doc.pytest.org/en/latest/fixture.html
