import { Controller } from "@hotwired/stimulus";
import { makeTurboStreamRequest } from "utils/shared"; // Connects to data-controller="inbox"
import { unsubscribeFromSender } from "../utils/unsubscribe";

// Connects to data-controller="inbox"
export default class extends Controller {
  static targets = [
    "optionsToggleButton",
    "loadMoreButton",
    "resyncIconButton",
    "disposeIconButton",
    "protectIconButton",
    "unprotectIconButton",
    "moveIconButton",
    "sendersTable",
    "loadingSendersTable",
    "senderCheckbox",
  ];

  get selectedSenders() {
    return this.senderCheckboxTargets
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.id);
  }

  initialize() {
    makeTurboStreamRequest("dashboard/sync", "POST");
  }

  showLoadingState(event) {
    this.sendersTableTarget.classList.add("hidden");
    this.loadingSendersTableTarget.classList.remove("hidden");
    this.#disableInboxActions([event.params.enable]);
  }

  protectSenders() {
    this.#disableInboxActions();
    makeTurboStreamRequest("/senders/protect", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  unprotectSenders() {
    this.#disableInboxActions();
    makeTurboStreamRequest("/senders/unprotect", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  disposeAllFromSenders() {
    makeTurboStreamRequest("/senders/dispose_all", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  unsubscribeFromSender(event) {
    event.preventDefault();
    const params = event.params;
    const unsubscribeButton = event.target;
    unsubscribeFromSender(
      params.senderId,
      params.senderEmail,
      unsubscribeButton
    );
  }

  handleClickSenderAction(event) {
    event.stopPropagation();

    setTimeout(() => {
      this.#disableSenderActions(event);
    }, 10);
  }

  showLabelsModal(event) {
    event.preventDefault();
    event.stopPropagation();

    let senderIds = event.params.senderId
      ? [event.params.senderId]
      : this.selectedSenders;
    if (senderIds.length === 0) return;

    const url = new URL("/senders/labels_modal", window.location.origin);
    url.searchParams.set("sender_ids", JSON.stringify(senderIds));

    makeTurboStreamRequest(url.toString(), "GET");
  }

  handleClickSenderCheckbox(event) {
    event.stopPropagation();

    const buttons = [
      this.disposeIconButtonTarget,
      this.protectIconButtonTarget,
      this.unprotectIconButtonTarget,
      this.moveIconButtonTarget,
    ];
    if (this.selectedSenders.length > 0) {
      buttons.forEach((button) => (button.disabled = false));
    } else {
      buttons.forEach((button) => (button.disabled = true));
    }
  }

  #disableInboxActions(actionsToEnable = []) {
    const buttons = [
      this.loadMoreButtonTarget,
      this.resyncIconButtonTarget,
      this.disposeIconButtonTarget,
      this.protectIconButtonTarget,
      this.unprotectIconButtonTarget,
      this.moveIconButtonTarget,
    ];

    setTimeout(() => {
      if (!actionsToEnable.includes("options")) {
        buttons.push(this.optionsToggleButtonTarget);
      }

      buttons.forEach((button) => (button.disabled = true));
    }, 10);
  }

  #disableSenderActions(event) {
    const parentSenderRow = event.target.closest(".sender-row");

    const buttonsToDisable = [
      ".sender-load-more-button",
      ".sender-protect-all-button",
      ".sender-dispose-all-button",
    ];

    buttonsToDisable.forEach((button) => {
      const buttonElement = parentSenderRow.querySelector(button);
      if (buttonElement) buttonElement.disabled = true;
    });
  }
}
