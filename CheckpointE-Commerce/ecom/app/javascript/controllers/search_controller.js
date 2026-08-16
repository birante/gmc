import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input",
    "dropdown",
    "productsSection", "productsList",
    "shopsSection", "shopsList",
    "categoriesSection", "categoriesList",
    "empty", "loading", "footer", "footerLink"
  ]

  static values = {
    url: String,
    minLength: { type: Number, default: 2 },
    debounce: { type: Number, default: 250 },
    seeAllUrl: String
  }

  connect() {
    this._timer = null
    this._abortController = null
    this._currentQuery = ""
    this._activeIndex = -1
    this._items = []
    this._boundClickOutside = this._handleClickOutside.bind(this)
    document.addEventListener("click", this._boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._boundClickOutside)
    if (this._timer) clearTimeout(this._timer)
    if (this._abortController) this._abortController.abort()
  }

  onInput() {
    const q = this.inputTarget.value.trim()
    this._activeIndex = -1
    if (this._timer) clearTimeout(this._timer)

    if (q.length < this.minLengthValue) {
      this._closeDropdown()
      return
    }

    this._timer = setTimeout(() => this._fetch(q), this.debounceValue)
  }

  onFocus() {
    if (this._currentQuery && this._items.length) {
      this._openDropdown()
    }
  }

  onKeydown(event) {
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this._moveActive(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this._moveActive(-1)
        break
      case "Enter":
        if (this._activeIndex >= 0 && this._items[this._activeIndex]) {
          event.preventDefault()
          window.location.href = this._items[this._activeIndex].url
        }
        break
      case "Escape":
        this._closeDropdown()
        this.inputTarget.blur()
        break
    }
  }

  async _fetch(q) {
    if (this._abortController) this._abortController.abort()
    this._abortController = new AbortController()

    this._showLoading()

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", q)
      const response = await fetch(url.toString(), {
        signal: this._abortController.signal,
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json()
      this._currentQuery = q
      this._render(data)
    } catch (e) {
      if (e.name === "AbortError") return
      console.error("[search]", e)
      this._closeDropdown()
    } finally {
      this._hideLoading()
    }
  }

  _render(data) {
    this._items = []

    this._renderSection(
      data.products,
      this.hasProductsListTarget ? this.productsListTarget : null,
      this.hasProductsSectionTarget ? this.productsSectionTarget : null,
      (p) => this._buildProductRow(p)
    )

    this._renderSection(
      data.shops,
      this.hasShopsListTarget ? this.shopsListTarget : null,
      this.hasShopsSectionTarget ? this.shopsSectionTarget : null,
      (s) => this._buildShopRow(s)
    )

    this._renderSection(
      data.categories,
      this.hasCategoriesListTarget ? this.categoriesListTarget : null,
      this.hasCategoriesSectionTarget ? this.categoriesSectionTarget : null,
      (c) => this._buildCategoryRow(c)
    )

    const total = this._items.length

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", total > 0)
    }

    if (this.hasFooterTarget) {
      this.footerTarget.classList.toggle("hidden", total === 0)
    }
    if (this.hasFooterLinkTarget && this.seeAllUrlValue) {
      const url = new URL(this.seeAllUrlValue, window.location.origin)
      url.searchParams.set("search", this._currentQuery)
      this.footerLinkTarget.href = url.pathname + url.search
      this.footerLinkTarget.textContent = `Voir tous les résultats pour "${this._currentQuery}"`
    }

    this._openDropdown()
  }

  _renderSection(records, listTarget, sectionTarget, buildFn) {
    if (!listTarget || !sectionTarget) return
    listTarget.innerHTML = ""
    if (records && records.length) {
      records.forEach((r) => {
        listTarget.appendChild(buildFn(r))
        this._items.push(r)
      })
      sectionTarget.classList.remove("hidden")
    } else {
      sectionTarget.classList.add("hidden")
    }
  }

  _buildProductRow(p) {
    const a = this._buildRowLink(p.url)
    a.appendChild(this._buildThumb(p.image_url, "rounded"))

    const text = document.createElement("div")
    text.className = "flex-1 min-w-0"
    text.appendChild(this._buildLine("text-sm text-gray-900 truncate", p.name))

    const priceText = p.price ? `${this._formatPrice(p.price)} ${p.currency_symbol || ""}`.trim() : ""
    const shopText = p.shop_name ? ` · ${p.shop_name}` : ""
    text.appendChild(this._buildLine("text-xs text-gray-500 truncate", priceText + shopText))

    a.appendChild(text)
    return a
  }

  _buildShopRow(s) {
    const a = this._buildRowLink(s.url)
    a.appendChild(this._buildThumb(s.logo_url, "rounded-full"))

    const text = document.createElement("div")
    text.className = "flex-1 min-w-0"
    text.appendChild(this._buildLine("text-sm text-gray-900 truncate", s.name))

    a.appendChild(text)
    return a
  }

  _buildCategoryRow(c) {
    const a = this._buildRowLink(c.url)

    const icon = document.createElement("div")
    icon.className = "w-10 h-10 rounded bg-gray-100 flex items-center justify-center flex-shrink-0"
    icon.innerHTML = '<svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>'
    a.appendChild(icon)

    const text = document.createElement("div")
    text.className = "flex-1 min-w-0 text-sm text-gray-900 truncate"
    text.textContent = c.name
    a.appendChild(text)

    return a
  }

  _buildRowLink(href) {
    const a = document.createElement("a")
    a.href = href
    a.className = "flex items-center gap-3 px-4 py-2 hover:bg-gray-50 transition-colors"
    a.dataset.searchItem = "true"
    return a
  }

  _buildThumb(src, shape) {
    const img = document.createElement("img")
    img.src = src || "/icon.svg"
    img.alt = ""
    img.loading = "lazy"
    img.className = `w-10 h-10 ${shape} object-cover bg-gray-100 flex-shrink-0`
    img.onerror = () => { img.src = "/icon.svg" }
    return img
  }

  _buildLine(className, text) {
    const el = document.createElement("div")
    el.className = className
    el.textContent = text
    return el
  }

  _moveActive(delta) {
    const links = Array.from(this.dropdownTarget.querySelectorAll('a[data-search-item="true"]'))
    if (!links.length) return

    if (this._activeIndex >= 0 && links[this._activeIndex]) {
      links[this._activeIndex].classList.remove("bg-gray-100")
    }

    this._activeIndex = (this._activeIndex + delta + links.length) % links.length
    const next = links[this._activeIndex]
    if (next) {
      next.classList.add("bg-gray-100")
      next.scrollIntoView({ block: "nearest" })
    }
  }

  _openDropdown() {
    this.dropdownTarget.classList.remove("hidden")
  }

  _closeDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this._activeIndex = -1
  }

  _showLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove("hidden")
  }

  _hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.add("hidden")
  }

  _formatPrice(price) {
    const num = Number(price)
    if (isNaN(num)) return ""
    return num.toLocaleString("fr-FR", { maximumFractionDigits: 0 })
  }

  _handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this._closeDropdown()
    }
  }
}
