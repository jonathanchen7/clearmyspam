import { Controller } from "@hotwired/stimulus"; // Connects to data-controller="options"

// Connects to data-controller="options"
export default class extends Controller {
  static targets = [
    "toggleDropdownButton",
    "caretIcon",
    "dropdownContainer",
    "hidePersonalEmailsToggle",
    "unreadOnlyToggle",
    "trashOption",
    "archiveOption",
  ];

  connect() {
    document.addEventListener(
      "click",
      this.#checkIfDropdownShouldClose.bind(this),
    );
  }

  disconnect() {
    document.removeEventListener(
      "click",
      this.#checkIfDropdownShouldClose.bind(this),
    );
  }

  toggleDropdown() {
    this.dropdownContainerTarget.classList.toggle("hidden");
  }

  closeDropdown() {
    this.dropdownContainerTarget.classList.add("hidden");
  }

  disableOptions() {
    const targetsToDisable = [
      this.hidePersonalEmailsToggleTarget,
      this.unreadOnlyToggleTarget,
      this.trashOptionTarget,
      this.archiveOptionTarget,
    ];

    setTimeout(() => {
      targetsToDisable.forEach((target) =>
        target.setAttribute("disabled", true),
      );
    }, 10);
  }

  #checkIfDropdownShouldClose(event) {
    if (
      !this.toggleDropdownButtonTarget.contains(event.target) &&
      !this.dropdownContainerTarget.contains(event.target)
    ) {
      this.closeDropdown();
    }
  }
}
