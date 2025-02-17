import { Controller } from "@hotwired/stimulus";
import { makeTurboStreamRequest } from "utils/shared"; // Connects to data-controller="inbox"

// Connects to data-controller="inbox"
export default class extends Controller {
  static targets = [
    "optionsToggleButton",
    "loadMoreButton",
    "resyncIconButton",
    "disposeIconButton",
    "protectIconButton",
    "unprotectIconButton",
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

  disposeSelected() {
    this.#disableInboxActions();
    makeTurboStreamRequest("/emails/dispose", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  disposeAllFromSenders(event) {
    makeTurboStreamRequest("/emails/dispose_all", "POST", {
      sender_emails: event.params.senderEmails,
    });
  }

  protectSelected() {
    this.#disableInboxActions();
    makeTurboStreamRequest("/emails/protect", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  unprotectSelected() {
    this.#disableInboxActions();
    makeTurboStreamRequest("/emails/unprotect", "POST", {
      sender_ids: this.selectedSenders,
    });
  }

  handleClickSenderAction(event) {
    event.stopPropagation();

    setTimeout(() => {
      this.#disableSenderActions(event);
    }, 10);
  }

  handleClickSenderCheckbox(event) {
    event.stopPropagation();

    const buttons = [
      this.disposeIconButtonTarget,
      this.protectIconButtonTarget,
      this.unprotectIconButtonTarget,
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
      parentSenderRow.querySelector(button).disabled = true;
    });
  }
}
