const Hooks = {}

Hooks.ModalWindow = {
  mounted() {
    this.clickListener = (event) => {
      if (event.target.id === "modal-overlay") {
        this.pushEvent("hide_modal", {})
      }
    }
    document.addEventListener("click", this.clickListener)

    this.escListener = (event) => {
      if (event.keyCode == 27) {
        this.pushEvent("hide_modal", {})
      }
    }
    document.addEventListener("keydown", this.escListener)

    const container = document.getElementsByClassName("container")[0]
    if (container) {
      container.classList.add("container_unscrolable")
    }
  },
  destroyed() {
    if (this.clickListener) {
      document.removeEventListener("click", this.clickListener)
    }
    if (this.escListener) {
      document.removeEventListener("keydown", this.escListener)
    }
  },
}
