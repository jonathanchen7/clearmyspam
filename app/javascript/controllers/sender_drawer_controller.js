import { Controller } from "@hotwired/stimulus";
import { makeTurboStreamRequest } from "utils/shared";
import { unsubscribeFromSender } from "../utils/unsubscribe";

export default class extends Controller {
	static targets = [
		"drawerContainer",
		"drawer",
		"closeButton",
		"selectAllCheckbox",
		"selectAllFromSenderBanner",
		"selectAllFromSenderBannerText",
		"selectAllFromSenderButton",
		"email",
		"emailCheckbox",
		"disposeIconButton",
		"protectIconButton",
		"unprotectIconButton",
		"unsubscribeButton",
		"previousPageButton",
		"nextPageButton",
		"backButton",
		"selectAllContainer",
		"paginationContainer",
	];
	static values = {
		senderId: String,
		senderEmail: String,
		page: Number,
		emailCount: Number,
		emailsPerPage: Number,
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

		this.currentPreviewEmail = null;

		if (this.emailTargets.length === 0) {
			makeTurboStreamRequest(
				`senders/${this.senderIdValue}/emails?page=${this.pageValue}`,
				"GET",
			);
		}
	}

	backButtonTargetConnected(target) {
		target.style.display = "none";
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

			this.#showSelectAllBanner();
		} else {
			this.emailCheckboxTargets.forEach((checkbox) => {
				checkbox.checked = false;
			});

			this.#hideSelectAllBanner();
		}

		this.updateIconButtonsState();
	}

	toggleSelectAllFromSender(event) {
		if (this.selectAllFromSender) {
			this.selectAllFromSenderBannerTextTarget.innerHTML = `All <b class="text-primary">${event.params.emailsOnPage}</b> email(s) on this page are selected.`;
			this.selectAllFromSenderButtonTarget.textContent = `Select all ${event.params.senderCount} from ${event.params.senderEmail}`;
			this.selectAllFromSender = false;
		} else {
			this.selectAllFromSenderBannerTextTarget.innerHTML = `All <b class="text-primary">${event.params.senderCount}</b> emails from <span class="text-primary">${event.params.senderEmail}</span> are selected.`;
			this.selectAllFromSenderButtonTarget.textContent = "Clear selection";
			this.selectAllFromSender = true;
		}
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

		if (this.#selectedEmailIds.length === this.emailCheckboxTargets.length) {
			this.#showSelectAllBanner();
		} else {
			this.#hideSelectAllBanner();
		}

		this.updateIconButtonsState();
	}

	updateIconButtonsState() {
		const selectedEmailCount = this.#selectedEmailIds.length;
		this.protectIconButtonTarget.disabled = selectedEmailCount === 0;
		this.unprotectIconButtonTarget.disabled = selectedEmailCount === 0;
		this.disposeIconButtonTarget.disabled = selectedEmailCount === 0;
	}

	#showSelectAllBanner() {
		if (this.emailCountValue > this.emailsPerPageValue) {
			this.selectAllFromSenderBannerTarget.classList.remove("hidden");
		}
	}

	#hideSelectAllBanner() {
		if (this.emailCountValue > this.emailsPerPageValue) {
			this.selectAllFromSenderBannerTarget.classList.add("hidden");
		}
	}

	// ------------------ ACTIONS ------------------

	previousPage() {
		makeTurboStreamRequest(
			`senders/${this.senderIdValue}?page=${this.pageValue - 1}`,
			"GET",
			null,
			this.previousPageButtonTarget,
		);
	}

	nextPage() {
		makeTurboStreamRequest(
			`senders/${this.senderIdValue}?page=${this.pageValue + 1}`,
			"GET",
			null,
			this.nextPageButtonTarget,
		);
	}

	backToSender() {
		makeTurboStreamRequest(
			`senders/${this.senderIdValue}?page=${this.pageValue}`,
			"GET",
			null,
			this.backButtonTarget,
		);
	}

	unsubscribe() {
		unsubscribeFromSender(
			this.senderIdValue,
			this.senderEmailValue,
			this.unsubscribeButtonTarget,
		);
	}

	disableActions(_) {
		this.selectAllCheckboxTarget.disabled = true;
		this.protectIconButtonTarget.disabled = true;
		this.unprotectIconButtonTarget.disabled = true;
		this.disposeIconButtonTarget.disabled = true;
		this.unsubscribeButtonTarget.disabled = true;
	}

	toggleProtection(event) {
		event.stopPropagation();

		const isProtected = this.currentPreviewEmail
			? this.currentPreviewEmail.protected
			: event.params.protected;
		const emailId = this.currentPreviewEmail
			? this.currentPreviewEmail.id
			: event.params.emailId;
		makeTurboStreamRequest(
			isProtected ? `emails/unprotect` : `emails/protect`,
			"POST",
			this.#turboRequestBody({ email_ids: [emailId] }),
			event.target.closest("button"),
		);
	}

	dispose(event) {
		event.stopPropagation();

		if (this.selectAllFromSender) {
			makeTurboStreamRequest(
				`senders/dispose_all`,
				"POST",
				this.#turboRequestBody({ sender_ids: [this.senderIdValue] }),
				event.target.closest("button"),
			);
		} else {
			let emailIds;
			if (this.currentPreviewEmail) {
				emailIds = [this.currentPreviewEmail.id];
			} else if (event.params.emailId) {
				emailIds = [event.params.emailId];
			} else {
				emailIds = this.#selectedEmailIds;
			}
			makeTurboStreamRequest(
				`emails/dispose`,
				"POST",
				this.#turboRequestBody({ email_ids: emailIds }),
				event.target.closest("button"),
			);
		}
	}

	protectSelected() {
		if (this.selectAllFromSender) {
			makeTurboStreamRequest(
				`senders/protect`,
				"POST",
				this.#turboRequestBody({ sender_ids: [this.senderIdValue] }),
				this.protectIconButtonTarget,
			);
		} else {
			const emailIds = this.currentPreviewEmail
				? [this.currentPreviewEmail.id]
				: this.#selectedEmailIds;
			makeTurboStreamRequest(
				`emails/protect`,
				"POST",
				this.#turboRequestBody({ email_ids: emailIds }),
				this.protectIconButtonTarget,
			);
		}
	}

	unprotectSelected() {
		if (this.selectAllFromSender) {
			makeTurboStreamRequest(
				`senders/unprotect`,
				"POST",
				this.#turboRequestBody({ sender_ids: [this.senderIdValue] }),
				this.unprotectIconButtonTarget,
			);
		} else {
			const emailIds = this.currentPreviewEmail
				? [this.currentPreviewEmail.id]
				: this.#selectedEmailIds;
			makeTurboStreamRequest(
				`emails/unprotect`,
				"POST",
				this.#turboRequestBody({ email_ids: emailIds }),
				this.unprotectIconButtonTarget,
			);
		}
	}

	#handleToastCtaClick(event) {
		if (event.detail.action === "disposeAll") {
			this.disableActions();
		}
	}

	previewEmail(event) {
		const threadId = event.params.threadId;
		const email = this.emailTargets.find(
			(el) => el.dataset.emailIdValue === threadId,
		);

		if (!email) return;

		this.currentPreviewEmail = {
			id: threadId,
			protected: email.dataset.protectedValue === "true",
		};

		this.emailCheckboxTargets.forEach((checkbox) => {
			checkbox.checked = false;
		});

		this.#hideSelectAllBanner();
		this.updateIconButtonsState();
		this.#updateToolbarForEmailPreview();
	}

	#updateToolbarForEmailPreview() {
		this.backButtonTarget.style.display = "";
		this.selectAllContainerTarget.style.display = "none";
		this.paginationContainerTarget.style.display = "none";

		this.disposeIconButtonTarget.disabled = this.currentPreviewEmail.protected;

		this.protectIconButtonTarget.disabled = this.currentPreviewEmail.protected;
		this.unprotectIconButtonTarget.disabled =
			!this.currentPreviewEmail.protected;
	}

	#turboRequestBody(body = {}) {
		return {
			...body,
			drawer_options: {
				enabled: true,
				page: this.pageValue,
				sender_id: this.senderIdValue,
			},
		};
	}
}
