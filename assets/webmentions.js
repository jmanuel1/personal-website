---
---

const webmentions = fetch(`https://webmention.io/api/links.jf2?target={{ site.publish_url }}${window.location.pathname}`)
  .then(response => response.json())
  .then(webmentions => onDOMLoad(() => {
    const webmentionsList = document.getElementById('webmentions');

    for (let webmention of webmentions.children) {
      const element = document.createElement('li');
      addAuthor(element, webmention.author);
      webmentionsList.appendChild(element);
    }
  }));

function addAuthor(element, author) {
  photo = document.createElement('img');
  photo.src = author.photo;
  element.appendChild(photo);
  element.insertAdjacentText('beforeend', `Author: ${author.name}`);
}

function onDOMLoad(fun) {
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', fun);
  else fun();
}
