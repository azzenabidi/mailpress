import { Controller } from "@hotwired/stimulus"

// Copies the post permalink to the clipboard when clicked.
export default class extends Controller {
  static targets = ["label"]
  static values = { link: String }

  copy() {
    navigator.clipboard.writeText(this.linkValue).then(() => {
      this.labelTarget.textContent = "Copied!"
      setTimeout(() => { this.labelTarget.textContent = "Copy link" }, 1500)
    })
  }
}
