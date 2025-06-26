import { Controller } from "@hotwired/stimulus";
import { makeRequest, makeTurboStreamRequest } from "utils/shared"; // Connects to data-controller="sender-drawer"

// Connects to data-controller="sender-drawer"
export default class extends Controller {
  static targets = [
    "drawerContainer",
    "drawer",
    "closeButton",
    "selectAllCheckbox",
    "email",
    "emailCheckbox",
    "disposeIconButton",
    "protectIconButton",
    "unprotectIconButton",
    "unsubscribeButton",
    "loadMoreButton",
    "previousPageButton",
    "nextPageButton",
  ];
  static values = {
    senderId: String,
    senderEmail: String,
    page: Number,
  };

  // ------------------ GETTERS ------------------

  get #selectedEmailIds() {
    return this.emailCheckboxTargets
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
      this.#closeDrawer();
    }
  }

  #handleKeydown(e) {
    if (e.key === "Escape") {
      this.#closeDrawer();
    }
  }

  #closeDrawer() {
    const emptyDrawer = document.createElement("div");
    emptyDrawer.id = "sender_drawer";
    this.drawerContainerTarget.replaceWith(emptyDrawer);
  }

  // ------------------ SELECTING ------------------

  toggleSelectAll(event) {
    if (event.target.checked) {
      this.emailCheckboxTargets.forEach((checkbox) => {
        checkbox.checked = true;
      });
    } else {
      this.emailCheckboxTargets.forEach((checkbox) => {
        checkbox.checked = false;
      });
    }

    this.updateIconButtonsState();
  }

  selectEmail(e) {
    const emailContainer = e.target.closest(".email");
    const checkbox = emailContainer.querySelector("input[type=checkbox]");
    checkbox.click();

    this.checkboxClicked(e);
  }

  checkboxClicked(event) {
    event.stopPropagation();
    this.selectAllCheckboxTarget.checked =
      this.#selectedEmailIds.length === this.emailCheckboxTargets.length;

    this.updateIconButtonsState();
  }

  updateIconButtonsState() {
    const selectedEmailCount = this.#selectedEmailIds.length;
    this.protectIconButtonTarget.disabled = selectedEmailCount === 0;
    this.unprotectIconButtonTarget.disabled = selectedEmailCount === 0;
    this.disposeIconButtonTarget.disabled = selectedEmailCount === 0;
  }

  // ------------------ ACTIONS ------------------

  previousPage() {
    makeTurboStreamRequest(
      `senders/${this.senderIdValue}?page=${this.pageValue - 1}`,
      "GET",
      null,
      this.previousPageButtonTarget
    );
  }

  nextPage() {
    makeTurboStreamRequest(
      `senders/${this.senderIdValue}?page=${this.pageValue + 1}`,
      "GET",
      null,
      this.nextPageButtonTarget
    );
  }

  unsubscribe() {
    this.unsubscribeButtonTarget.disabled = true;

    const showUnsubscribeError = () =>
      alert(
        `We couldn't find any links to unsubscribe from ${this.senderEmailValue}.`
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
      isProtected ? `emails/unprotect` : `emails/protect`,
      "POST",
      this.#turboRequestBody([event.params.emailId]),
      event.target.closest("button")
    );
  }

  dispose(event) {
    event.stopPropagation();
    makeTurboStreamRequest(
      `emails/dispose`,
      "POST",
      this.#turboRequestBody([event.params.emailId]),
      event.target.closest("button")
    );
  }

  protectSelected() {
    makeTurboStreamRequest(
      `emails/protect`,
      "POST",
      this.#turboRequestBody(),
      this.protectIconButtonTarget
    );
  }

  unprotectSelected() {
    makeTurboStreamRequest(
      `emails/unprotect`,
      "POST",
      this.#turboRequestBody(),
      this.unprotectIconButtonTarget
    );
  }

  disposeSelected() {
    makeTurboStreamRequest(
      `emails/dispose`,
      "POST",
      this.#turboRequestBody(),
      this.disposeIconButtonTarget
    );
  }

  #handleToastCtaClick(event) {
    if (event.detail.action === "disposeAll") {
      this.disableActions();
    }
  }

  #turboRequestBody(emailIds = this.#selectedEmailIds) {
    return {
      email_ids: emailIds,
      drawer_options: {
        enabled: true,
        page: this.pageValue,
        sender_id: this.senderIdValue,
      },
    };
  }
}
