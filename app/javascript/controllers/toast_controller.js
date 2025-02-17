import { Controller } from "@hotwired/stimulus"; // Connects to data-controller="toast"

// Connects to data-controller="toast"
export default class extends Controller {
  static targets = ["toast"];

  toastTargetConnected(target) {
    if (target.id === "toast-placeholder") return;

    setTimeout(() => {
      this.#show(target);
    }, 100);

    setTimeout(() => {
      this.#close(target);
    }, 10000);
  }

  notify(event) {
    const { title, text } = event.params;

    const newToastContainer = this.#placeholder()
      .closest(".toast-container")
      .cloneNode(true);
    const notifications = document.getElementById("notifications");
    notifications.prepend(newToastContainer);

    const newToast = newToastContainer.querySelector(".toast");
    newToast.id = "";
    newToast.classList.remove("hidden");

    setTimeout(() => {
      this.#show(newToast, title, text);
    }, 100);

    setTimeout(() => {
      this.#close(newToast);
    }, 10000);
  }

  dismiss(event) {
    this.#close(event.target.closest(".toast"));
  }

  #show(toastTarget, title = null, text = null) {
    const titleTarget = toastTarget.querySelector(".toast-title");
    const textTarget = toastTarget.querySelector(".toast-text");
    if (title) titleTarget.textContent = title;
    if (text) textTarget.textContent = text;

    if (textTarget.textContent) {
      const textRowTarget = toastTarget.querySelector(".toast-text-row");
      textRowTarget.classList.remove("hidden"); // Only show the bottom row if there is content.
    }

    this.#repositionToasts();

    toastTarget.classList.remove(
      "translate-y-2",
      "opacity-0",
      "sm:translate-y-0",
      "sm:translate-x-2",
    );
    toastTarget.classList.add(
      "transform",
      "ease-out",
      "duration-300",
      "transition",
      "translate-y-0",
      "opacity-100",
      "sm:translate-x-0",
    );
  }

  #close(toastTarget) {
    if (!toastTarget || toastTarget.classList.contains("hidden")) return;

    toastTarget.classList.remove(
      "translate-y-0",
      "opacity-100",
      "sm:translate-x-0",
    );
    toastTarget.classList.add(
      "transition",
      "ease-in",
      "duration-100",
      "opacity-0",
    );

    setTimeout(() => {
      toastTarget.closest(".toast-container").remove();
      this.#repositionToasts();
    }, 250);
  }

  #placeholder() {
    return document.getElementById("toast-placeholder");
  }

  #repositionToasts() {
    const toasts = document.querySelectorAll(".toast:not(.hidden)");
    toasts.forEach((toast, index) => {
      if (index !== 0) {
        const previousToastsHeight = Array.from(toasts)
          .slice(0, index)
          .reduce(
            (acc, t) =>
              acc -
              (window.innerWidth < 640
                ? t.offsetHeight + 8
                : t.offsetHeight + 16),
            0,
          );
        toast.style.transform = `translateY(${previousToastsHeight}px)`;
      } else {
        toast.style.transform = `translateY(0)`;
      }
    });
  }
}
