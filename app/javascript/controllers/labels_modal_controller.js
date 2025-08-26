import { Controller } from "@hotwired/stimulus";
import { makeTurboStreamRequest } from "utils/shared";

export default class extends Controller {
  static targets = ["labelsList"];

  connect() {
    document.body.classList.add("overflow-hidden");
  }

  disconnect() {
    document.body.classList.remove("overflow-hidden");
  }

  close() {
    const emptyModal = document.createElement("div");
    emptyModal.id = "labels_modal";
    this.element.replaceWith(emptyModal);
  }

  async selectLabel(event) {
    const labelId = event.currentTarget.dataset.labelId;

    const senderIds = this.element.dataset.senderIds
      ? JSON.parse(this.element.dataset.senderIds)
      : [];

    if (senderIds.length === 0) return;

    event.currentTarget.disabled = true;
    event.currentTarget.innerHTML = `
      <div class="flex items-center justify-center text-xs">
        <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="text-xs">Moving...</p>
      </div>
    `;

    await makeTurboStreamRequest("/senders/move_all", "POST", {
      sender_ids: senderIds,
      label_id: labelId,
    });

    setTimeout(() => this.close(), 500);
  }
}
