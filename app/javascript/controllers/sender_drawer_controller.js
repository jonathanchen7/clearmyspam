import { Controller } from "@hotwired/stimulus";
import { makeRequest, makeTurboStreamRequest } from "utils/shared"; // Connects to data-controller="sender-drawer"

// Connects to data-controller="sender-drawer"
export default class extends Controller {
  static targets = [
    "drawerContainer",
    "drawer",
    "closeButton",
    "selectAllCheckbox",
    "emailThread",
    "emailThreadCheckbox",
    "disposeIconButton",
    "protectIconButton",
    "unprotectIconButton",
    "unsubscribeButton",
    "loadMoreButton",
  ];
  static values = {
    senderId: String,
    senderEmail: String,
  };

  // ------------------ GETTERS ------------------

  get #selectedEmailIds() {
    return this.emailThreadCheckboxTargets
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.id);
  }

  // ------------------ CONNECT + DISCONNECT ------------------

  connect() {
    this.boundCheckIfDrawerShouldClose =
      this.#checkIfDrawerShouldClose.bind(this);
    this.boundHandleKeydown = this.#handleKeydown.bind(this);
    this.boundHandleToastCtaClick = this.#handleToastCtaClick.bind(this);

    document.addEventListener("click", this.boundCheckIfDrawerShouldClose);
    document.addEventListener("keydown", this.boundHandleKeydown);
    window.addEventListener("toast:ctaClick", this.boundHandleToastCtaClick);

    document.body.classList.add("overflow-hidden");
  }

  disconnect() {
    document.removeEventListener("click", this.boundCheckIfDrawerShouldClose);
    document.removeEventListener("keydown", this.boundHandleKeydown);
    window.removeEventListener("toast:ctaClick", this.boundHandleToastCtaClick);

    document.body.classList.remove("overflow-hidden");
  }

  #checkIfDrawerShouldClose(e) {
    if (!this.hasCloseButtonTarget || !this.hasDrawerTarget) return;

    if (
      this.closeButtonTarget.contains(e.target) ||
      (!this.drawerTarget.contains(e.target) && !e.target.closest(".toast"))
    ) {
      this.drawerContainerTarget.remove();
    }
  }

  #handleKeydown(e) {
    if (e.key === "Escape") {
      this.drawerContainerTarget.remove();
    }
  }

  // ------------------ SELECTING ------------------

  toggleSelectAll(event) {
    if (event.target.checked) {
      this.emailThreadCheckboxTargets.forEach((checkbox) => {
        checkbox.checked = true;
      });
    } else {
      this.emailThreadCheckboxTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }

    this.updateIconButtonsState();
  }

  selectEmailThread(e) {
    const emailThreadContainer = e.target.closest(".email-thread");
    const checkbox = emailThreadContainer.querySelector("input[type=checkbox]");
    checkbox.click();

    this.checkboxClicked(e);
  }

  checkboxClicked(event) {
    event.stopPropagation();
    this.selectAllCheckboxTarget.checked =
      this.#selectedEmailIds.length === this.emailThreadCheckboxTargets.length;

    this.updateIconButtonsState();
  }

  updateIconButtonsState() {
    const selectedEmailCount = this.#selectedEmailIds.length;
    this.protectIconButtonTarget.disabled = selectedEmailCount === 0;
    this.unprotectIconButtonTarget.disabled = selectedEmailCount === 0;
    this.disposeIconButtonTarget.disabled = selectedEmailCount === 0;
  }

  // ------------------ ACTIONS ------------------

  unsubscribe() {
    this.unsubscribeButtonTarget.disabled = true;

    const showUnsubscribeError = () =>
      alert(
        `We couldn't find any links to unsubscribe from ${this.senderEmailValue}.`,
      );

    makeRequest(`/senders/${this.senderIdValue}/unsubscribe`, "POST")
      .then((response) => {
        if (response.success && response.url) {
          window.open(response.url, "_blank");
        } else {
          showUnsubscribeError();
        }
      })
      .catch(() => showUnsubscribeError());
  }

  disableActions(_) {
    this.selectAllCheckboxTarget.disabled = true;
    this.protectIconButtonTarget.disabled = true;
    this.unprotectIconButtonTarget.disabled = true;
    this.disposeIconButtonTarget.disabled = true;
    this.unsubscribeButtonTarget.disabled = true;
    this.loadMoreButtonTarget.disabled = true;
  }

  toggleProtection(event) {
    event.stopPropagation();
    const isProtected = event.params.protected === true;
    makeTurboStreamRequest(
      isProtected ? "emails/unprotect" : "emails/protect",
      "POST",
      this.#turboRequestBody([event.params.emailThreadId]),
      event.target.closest("button"),
    );
  }

  dispose(event) {
    event.stopPropagation();
    makeTurboStreamRequest(
      "emails/dispose",
      "POST",
      this.#turboRequestBody([event.params.emailThreadId]),
      event.target.closest("button"),
    );
  }

  protectSelected() {
    makeTurboStreamRequest(
      "/emails/protect",
      "POST",
      this.#turboRequestBody(),
      this.protectIconButtonTarget,
    );
  }

  unprotectSelected() {
    makeTurboStreamRequest(
      "/emails/unprotect",
      "POST",
      this.#turboRequestBody(this.#selectedEmailIds),
      this.unprotectIconButtonTarget,
    );
  }

  disposeSelected() {
    makeTurboStreamRequest(
      "/emails/dispose",
      "POST",
      this.#turboRequestBody(),
      this.disposeIconButtonTarget,
    );
  }

  #handleToastCtaClick(event) {
    if (event.detail.action === "disposeAll") {
      this.disableActions();
    }
  }

  #turboRequestBody(emailThreadIds = this.#selectedEmailIds) {
    let result = {
      drawer_options: {
        enabled: true,
        sender_id: this.senderIdValue,
      },
    };
    if (emailThreadIds.length === this.emailThreadCheckboxTargets.length) {
      result["sender_ids"] = [this.senderIdValue];
    } else {
      result["email_thread_ids"] = emailThreadIds;
    }

    return result;
  }
}
