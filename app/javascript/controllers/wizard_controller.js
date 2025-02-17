import { Controller } from "@hotwired/stimulus"; // Connects to data-controller="wizard"

// Connects to data-controller="wizard"
export default class extends Controller {
  connect() {
    document.body.classList.add("overflow-hidden");
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden");
  }
}
