import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="admin"
export default class extends Controller {
	static targets = ["dateRangeSelect", "sortSelect"];

	updateFilters() {
		const dateRange = this.dateRangeSelectTarget.value;
		const sortBy = this.sortSelectTarget.value;
		const page = new URLSearchParams(window.location.search).get("page") || "1";

		window.location.href = `/admin?date_range=${dateRange}&sort_by=${sortBy}&page=${page}`;
	}

	updateDateRange() {
		this.updateFilters();
	}

	updateSort() {
		this.updateFilters();
	}
}
