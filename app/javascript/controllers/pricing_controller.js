import { Controller } from "@hotwired/stimulus";
import { makeRequest } from "utils/shared";

// Connects to data-controller="pricing"
export default class extends Controller {
  static values = { planType: String };

  checkout() {
    makeRequest(`/pricing/checkout?type=${this.planTypeValue}`, "POST").then(
      (result) => {
        if (result.success && result.url) {
          window.location.replace(result.url);
        }
      },
    );
  }
}
