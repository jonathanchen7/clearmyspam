import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="navigation"
export default class extends Controller {
  static targets = ["mobileMenuIcon", "mobileMenu"];

  connect() {
    document.addEventListener("click", this.handleClick.bind(this));
  }

  disconnect() {
    document.removeEventListener("click", this.handleClick.bind(this));
  }

  toggleMobileMenu() {
    this.mobileMenuTarget.classList.toggle("hidden");
  }

  handleClick(event) {
    if (
      !this.mobileMenuTarget.contains(event.target) &&
      !this.mobileMenuIconTarget.contains(event.target)
    ) {
      this.mobileMenuTarget.classList.add("hidden");
    }
  }
}
