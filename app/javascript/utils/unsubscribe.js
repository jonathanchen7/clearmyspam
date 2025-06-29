import { makeRequest } from "./shared";

export function unsubscribeFromSender(
  senderId,
  senderEmail,
  unsubscribeButton
) {
  unsubscribeButton.disabled = true;

  const showUnsubscribeError = () =>
    alert(`We couldn't find any links to unsubscribe from ${senderEmail}.`);

  makeRequest(`/senders/${senderId}/unsubscribe`, "POST")
    .then((response) => {
      if (response.success && response.url) {
        window.open(response.url, "_blank");
        unsubscribeButton.textContent = "Unsubscribed";
      } else {
        showUnsubscribeError();
      }
    })
    .catch(() => showUnsubscribeError());
}
