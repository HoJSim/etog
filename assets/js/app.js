// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.

// eslint-disable-next-line
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import { Socket } from "phoenix"
import LiveSocket from "phoenix_live_view"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

const setCookie = function (key, value) {
  let expiration = new Date()
  expiration.setFullYear(expiration.getFullYear() + 1)
  document.cookie = `${key}=${value}; path=/; domain=.${
    window.location.hostname
  }; expires=${expiration.toUTCString()}`
}

const Hooks = {}
Hooks.ThemeSelector = {
  mounted() {
    this.el.addEventListener("click", () => {
      const body = document.getElementsByTagName("body")[0]
      let isDark = body.classList.contains("is-dark")
      let isLight = body.classList.contains("is-light")

      if (!isDark && !isLight) {
        isDark =
          window.matchMedia &&
          window.matchMedia("(prefers-color-scheme: dark)").matches
        isLight = !isDark
      }

      if (isDark) {
        body.classList.add("is-light")
        body.classList.remove("is-dark")
        setCookie("color-scheme", "light")
      } else {
        body.classList.add("is-dark")
        body.classList.remove("is-light")
        setCookie("color-scheme", "dark")
      }
    })
  },
}

Hooks.LocaleSelector = {
  mounted() {
    this.el.addEventListener("click", () => {
      const locale = this.el.dataset.locale
      setCookie("locale", locale)
      window.location.reload()
    })
  },
}

const main = function () {
  const csrfToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute("content")
  const liveSocket = new LiveSocket("/live", Socket, {
    hooks: Hooks,
    params: { _csrf_token: csrfToken },
  })
  liveSocket.connect()
}

if (!!window.MSInputMethodContext && !!document.documentMode) {
  const src = document
    .querySelector("meta[name='ie-polyfill-path']")
    .getAttribute("content")
  const js = document.createElement("script")
  js.src = src
  js.onload = function () {
    main()
  }
  js.onerror = function () {
    new Error("Failed to load script " + src)
  }
  document.head.appendChild(js)
} else {
  main()
}
