import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="logo-uploader"
export default class extends Controller {
  static targets = ["fileInput", "previewImg", "placeholder", "removeCheckbox", "dropzone"]

  connect() {}

  choose(event) {
    event.preventDefault()
    if (this.hasFileInputTarget) this.fileInputTarget.click()
  }

  onFileChange(event) {
    const file = event.target.files && event.target.files[0]
    if (!file) return

    if (!/^image\/(png|jpe?g|webp)$/i.test(file.type)) {
      alert("Veuillez sélectionner une image PNG/JPG/WEBP.")
      event.target.value = ""
      return
    }

    const maxBytes = 2 * 1024 * 1024 // 2MB
    if (file.size > maxBytes) {
      alert("L'image dépasse 2 Mo. Merci de choisir un fichier plus léger.")
      event.target.value = ""
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewImgTarget) {
        this.previewImgTarget.src = e.target.result
        this.previewImgTarget.classList.remove("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }
      if (this.hasRemoveCheckboxTarget) {
        this.removeCheckboxTarget.checked = false
      }
    }
    reader.readAsDataURL(file)
  }

  onDragOver(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.add("ring-2", "ring-[#551694]")
  }

  onDragLeave(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.remove("ring-2", "ring-[#551694]")
  }

  onDrop(event) {
    event.preventDefault()
    if (this.hasDropzoneTarget) this.dropzoneTarget.classList.remove("ring-2", "ring-[#551694]")

    const dt = event.dataTransfer
    const file = dt && dt.files && dt.files[0]
    if (!file) return

    // Simule un changement sur l'input pour réutiliser la logique
    if (this.hasFileInputTarget) {
      const dT = new DataTransfer()
      dT.items.add(file)
      this.fileInputTarget.files = dT.files
      this.onFileChange({ target: this.fileInputTarget })
    }
  }
}
