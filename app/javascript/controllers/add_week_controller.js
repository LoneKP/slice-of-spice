import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    url: String,
  };

  connect() {
    console.log("Add week controller connected");
  }

  async addWeek(event) {
    event.preventDefault();
    console.log("Add week button clicked");
    console.log("Request URL:", this.urlValue);

    const button = event.currentTarget;
    button.disabled = true;

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
          Accept: "text/vnd.turbo-stream.html",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const html = await response.text();
      console.log("Response received:", html);

      // Let Turbo handle the stream
      Turbo.renderStreamMessage(html);
    } catch (error) {
      console.error("Error adding week:", error);
      alert("Failed to add week. Please try again.");
    } finally {
      button.disabled = false;
    }
  }
}
