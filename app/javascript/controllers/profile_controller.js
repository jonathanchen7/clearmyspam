import { Controller } from "@hotwired/stimulus";
import { makeRequest } from "utils/shared";

// Connects to data-controller="profile"
export default class extends Controller {
  static targets = ["profileChip", "dropdownContainer"];

  connect() {
    document.addEventListener("click", this.handleClick.bind(this));
  }

  disconnect() {
    document.removeEventListener("click", this.handleClick.bind(this));
  }

  toggleDropdown() {
    this.dropdownContainerTarget.classList.toggle("hidden");
  }

  openBilling() {
    makeRequest("/pricing/billing_portal", "POST").then((response) => {
      if (response.success && response.url) {
        // To avoid the certificate pop-ups you can open the link in a new tab.
        window.location.replace(response.url);
      }
    });
  }

  handleClick(event) {
    if (
      !this.profileChipTarget.contains(event.target) &&
      !this.dropdownContainerTarget.contains(event.target)
    ) {
      this.dropdownContainerTarget.classList.add("hidden");
    }
  }
}
