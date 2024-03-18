import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {

  static targets = ['container'];

  connect() {
    this.toggleClass = 'hidden';
    this.backgroundId = 'modal-background';
    this.backgroundHtml = this._backgroundHTML();
  }

  disconnect() {
    this.close();
  }

  open() {
    document.body.classList.add('fixed', 'inset-x-0', 'overflow-hidden');
    this.containerTarget.classList.remove(this.toggleClass);
    document.body.insertAdjacentHTML('beforeend', this.backgroundHtml);
    this.background = document.querySelector(`#${this.backgroundId}`);
  }

  submitEnd(e) {
    if (e.detail.success) {
    this.close()
    }
  }

  clickOutsideModalToClose(e) {
    if (e.target === document.getElementById("modal-container")) {
      this.close()
    }
  }

  close() {
    if (typeof event !== 'undefined') {
      event.preventDefault()
    }
    this.containerTarget.classList.add(this.toggleClass);
    if (this.background) { 
      this.background.remove() 
      document.body.classList.remove('fixed', 'inset-x-0', 'overflow-hidden');
    }
    
  }

  _backgroundHTML() {
    return `<div id="${this.backgroundId}" class="fixed top-0 left-0 w-full h-full" style="background-color: rgba(0, 0, 0, 0.7); z-index: 9998;"></div>`;
  }

}
