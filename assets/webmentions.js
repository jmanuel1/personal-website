---
---

const webmentions = fetch(`https://webmention.io/api/links.jf2?target={{ site.publish_url }}${window.location.pathname}`)
  .then(response => response.json())
  .then(webmentions => onDOMLoad(() => {
    const webmentionsList = document.getElementById('webmentions');

    for (let webmention of webmentions.children) {
      const element = document.createElement('li');
      addAuthor(element, webmention.author);
      addURL(element, webmention.url);
      addPublishedDate(element, webmention.published);
      webmentionsList.appendChild(element);
    }
  }));

function addAuthor(element, author) {
  const url = document.createElement('a');
  url.href = author.url;
  // TODO: Add alt
  const photo = document.createElement('img');
  photo.src = author.photo;
  url.appendChild(photo);
  url.insertAdjacentText('beforeend', `Author: ${author.name}`);
  element.appendChild(url);
}

function addURL(element, link) {
  element.appendChild(document.createElement('br'));
  const url = document.createElement('a');
  url.href = link;
  url.textContent = 'Source';
  element.appendChild(url);
}

function addPublishedDate(element, date) {
  const dateObject = new Date(date);
  const text = dateObject.toLocaleString();
  element.insertAdjacentText('beforeend', `Published: ${text}`);
}

function onDOMLoad(fun) {
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', fun);
  else fun();
}
