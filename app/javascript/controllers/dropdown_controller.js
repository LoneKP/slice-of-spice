// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  toggle(event) {
    event.preventDefault();

    if (this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.remove("hidden"); // show
    } else {
      this.menuTarget.classList.add("hidden"); // hide
    }
  }

  hide(event) {
    // only close if menu is open *and* you clicked outside this element
    if (
      !this.menuTarget.classList.contains("hidden") &&
      !this.element.contains(event.target)
    ) {
      this.menuTarget.classList.add("hidden");
    }
  }
}
