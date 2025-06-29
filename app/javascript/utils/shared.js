export function makeTurboStreamRequest(
  url,
  method,
  body = null,
  disableTarget = null,
  targetsToDisable = []
) {
  if (disableTarget) disableTarget.disabled = true;
  if (targetsToDisable.length > 0) {
    targetsToDisable.forEach((target) => (target.disabled = true));
  }

  fetch(url, {
    method: method,
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
      Accept: "text/vnd.turbo-stream.html",
    },
    body: body ? JSON.stringify(body) : null,
  })
    .then((response) => {
      if (!response.ok) throw new Error(response.statusText);

      return response.text();
    })
    .then((html) => {
      Turbo.renderStreamMessage(html);
    })
    .catch((error) => {
      console.log(error);
    })
    .finally(() => {
      if (disableTarget) disableTarget.disabled = false;
      if (targetsToDisable.length > 0) {
        targetsToDisable.forEach((target) => (target.disabled = false));
      }
    });
}

export function makeRequest(url, method, body = null) {
  return fetch(url, {
    method: method,
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
    },
    body: JSON.stringify(body),
  })
    .then((response) => {
      if (!response.ok) throw new Error(response.statusText);

      return response.json();
    })
    .catch((error) => {
      console.log(error);
    });
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]').content;
}
