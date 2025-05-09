import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["list"];
  static values = {
    url: String,
    maxItems: Number,
  };

  connect() {
    this.sortable = window.Sortable.create(this.listTarget, {
      group: "shared",
      animation: 150,
      ghostClass: "bg-gray-100",
      dragClass: "sortable-drag",
      handle: ".cursor-move",
      onEnd: this.handleSortEnd.bind(this),
      onStart: this.handleSortStart.bind(this),
    });
  }

  handleSortStart(event) {
    // Store the original state in case we need to revert
    this.originalState = {
      container: event.from,
      index: event.oldIndex,
      items: Array.from(event.from.children).map((item) => ({
        id: item.dataset.entryId,
        element: item,
      })),
    };
  }

  handleSortEnd(event) {
    const weekId = event.to.dataset.weekId;
    if (!weekId) {
      console.error("No week ID found on target container");
      this.revertSort(event);
      return;
    }

    const entries = Array.from(event.to.children).map((item, index) => ({
      id: item.dataset.entryId,
      position: index,
    }));

    console.log("Sending update with data:", {
      meal_plan_week_id: weekId,
      entries: entries,
    });

    // Update highlighting and day labels immediately
    this.updateHighlighting(event.to);
    this.updateDayLabels(event.to);

    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: JSON.stringify({
        meal_plan_week_id: weekId,
        entries: entries,
      }),
    })
      .then((response) => {
        if (!response.ok) {
          return response.text().then((text) => {
            console.error("Server response:", text);
            throw new Error(`HTTP error! status: ${response.status}`);
          });
        }
        return response.json();
      })
      .then((data) => {
        console.log("Server response data:", data);
        if (data.status === "error") {
          this.revertSort(event);
          this.showError(data.message);
        } else if (data.warning) {
          // Show warning but don't revert the move
          this.showWarning(data.warning);
        }
      })
      .catch((error) => {
        console.error("Error updating meal plan:", error);
        this.revertSort(event);
        this.showError("Failed to update meal plan. Please try again.");
      });
  }

  revertSort(event) {
    if (!this.originalState) {
      console.error("No original state to revert to");
      return;
    }

    // Revert the drag
    this.sortable.sort(this.originalState.items.map((item) => item.element));
    // Remove highlighting since we reverted
    this.updateHighlighting(event.to);
    this.updateDayLabels(event.to);
  }

  showError(message) {
    const flash = document.getElementById("flash");
    if (flash) {
      flash.innerHTML = `<div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
        <strong class="font-bold">Error!</strong>
        <span class="block sm:inline">${message}</span>
      </div>`;
      setTimeout(() => {
        flash.innerHTML = "";
      }, 3000);
    }
  }

  showWarning(message) {
    const flash = document.getElementById("flash");
    if (flash) {
      flash.innerHTML = `<div class="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded relative" role="alert">
        <strong class="font-bold">Warning!</strong>
        <span class="block sm:inline">${message}</span>
      </div>`;
      setTimeout(() => {
        flash.innerHTML = "";
      }, 3000);
    }
  }

  updateHighlighting(container) {
    const items = container.children;
    const maxItems = this.maxItemsValue;

    // Update the badge in the header
    const header = container.closest(".bg-white").querySelector(".bg-gray-50");
    const badge = header.querySelector(".inline-flex");

    if (items.length > maxItems) {
      if (!badge) {
        const newBadge = document.createElement("span");
        newBadge.className =
          "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800";
        newBadge.textContent = `${items.length}/${maxItems} meals`;
        header.appendChild(newBadge);
      } else {
        badge.textContent = `${items.length}/${maxItems} meals`;
      }
    } else if (badge) {
      badge.remove();
    }

    // Update the highlighting of items
    Array.from(items).forEach((item, index) => {
      if (index >= maxItems) {
        item.classList.add("bg-yellow-50");
      } else {
        item.classList.remove("bg-yellow-50");
      }
    });
  }

  updateDayLabels(container) {
    const items = container.children;
    Array.from(items).forEach((item, index) => {
      const dayLabel = item.querySelector(".text-sm.text-gray-500");
      if (dayLabel) {
        dayLabel.textContent = `Day ${index + 1}`;
      }
    });
  }
}
