import { Controller } from "@hotwired/stimulus"

// Sélecteur de variantes cross-attribut.
//
// L'utilisateur sélectionne une valeur par attribut (Couleur, Taille…) ; le
// controller cherche la variante exacte dans le payload, met à jour prix /
// stock / image / formulaire d'ajout au panier, marque les combinaisons
// impossibles ou en rupture, et synchronise l'URL via history.replaceState.
//
// HTML attendu :
//   <div data-controller="variant-selector"
//        data-variant-selector-variants-value='{"attributes":[...], "variants":[...], "currency_symbol":"FCFA"}'
//        data-variant-selector-initial-value="12">
//     <button data-variant-selector-target="option"
//             data-attr-name="Couleur" data-attr-value="Noir"
//             data-action="click->variant-selector#select">…</button>
//     …
//   </div>
export default class extends Controller {
  static targets = [
    "option",
    "price",
    "originalPrice",
    "discount",
    "stockBadge",
    "addToCart",
    "addToCartWrapper",
    "outOfStock",
    "variantInput",
    "quantityInput",
    "quantityHidden",
    "mainImage",
    "selectedValue"
  ]

  static values = {
    variants: Object,
    initial: Number
  }

  connect() {
    if (!this.variantsValue || !Array.isArray(this.variantsValue.variants)) {
      console.warn("[variant-selector] payload manquant ou invalide")
      return
    }

    this.attributes = this.variantsValue.attributes || []
    this.variants = this.variantsValue.variants || []
    this.currencySymbol = this.variantsValue.currency_symbol || ""

    // État courant : { "Couleur" => "Noir", "Taille" => "L" }
    this.selection = {}

    const initialVariant = this.findVariantById(this.initialValue)
    if (initialVariant) {
      Object.assign(this.selection, initialVariant.attrs || {})
    } else if (this.variants.length) {
      // Fallback : première variante en stock (sinon première tout court)
      const fallback = this.variants.find(v => v.in_stock) || this.variants[0]
      Object.assign(this.selection, fallback.attrs || {})
    }

    this.refresh()
  }

  // Handler de clic sur une option (swatch couleur ou bouton taille)
  select(event) {
    const button = event.currentTarget
    const name = button.dataset.attrName
    const value = button.dataset.attrValue
    if (!name || value == null) return

    // Toggle off si on reclique la valeur déjà sélectionnée — non, on garde
    // un comportement « radio » pour éviter les états ambigus.
    this.selection[name] = value
    this.refresh()
  }

  // Recalcule l'état complet à partir de this.selection.
  refresh() {
    const matched = this.matchingVariant()

    this.updateOptionStates()
    this.updateSelectedLabels()
    this.updatePriceAndStock(matched)
    this.updateForm(matched)
    this.updateImage(matched)
    this.updateUrl(matched)
  }

  // Cherche la variante dont les attrs == this.selection (toutes clés).
  matchingVariant() {
    return this.variants.find(v => {
      const a = v.attrs || {}
      return this.attributes.every(attr => a[attr.name] === this.selection[attr.name])
    }) || null
  }

  findVariantById(id) {
    if (!id) return null
    return this.variants.find(v => v.id === id) || null
  }

  // Pour chaque option, calcule :
  //  - selected : la valeur est dans this.selection
  //  - available : il existe au moins une variante en stock qui matche les
  //    AUTRES dimensions de la sélection courante + cette valeur. Sinon on
  //    grise/désactive (Babolat-style).
  updateOptionStates() {
    this.optionTargets.forEach(button => {
      const name = button.dataset.attrName
      const value = button.dataset.attrValue
      const isSelected = this.selection[name] === value

      const candidates = this.variants.filter(v => {
        const a = v.attrs || {}
        if (a[name] !== value) return false
        return this.attributes.every(attr => {
          if (attr.name === name) return true
          const chosen = this.selection[attr.name]
          if (chosen == null) return true
          return a[attr.name] === chosen
        })
      })

      const anyInStock = candidates.some(v => v.in_stock)
      const anyExists = candidates.length > 0

      button.dataset.selected = isSelected ? "true" : "false"
      button.dataset.available = anyInStock ? "true" : "false"

      button.classList.toggle("ring-2", isSelected)
      button.classList.toggle("ring-[#551694]", isSelected)
      button.classList.toggle("ring-offset-2", isSelected && button.dataset.optionStyle === "swatch")

      // Style swatch (couleur) : on garde une bordure visible.
      if (button.dataset.optionStyle === "swatch") {
        button.classList.toggle("border-[#551694]", isSelected)
        button.classList.toggle("border-gray-300", !isSelected)
      } else {
        // Style bouton (taille) : fond pourpre quand sélectionné.
        button.classList.toggle("bg-[#551694]", isSelected)
        button.classList.toggle("text-white", isSelected)
        button.classList.toggle("border-[#551694]", isSelected)
        button.classList.toggle("border-gray-300", !isSelected)
        button.classList.toggle("text-gray-900", !isSelected && anyInStock)
      }

      // Indispo : style barré / opacité.
      const unavailable = !anyExists || !anyInStock
      button.classList.toggle("opacity-40", unavailable && !isSelected)
      button.classList.toggle("line-through", unavailable && button.dataset.optionStyle !== "swatch")
      button.disabled = unavailable
      button.setAttribute("aria-disabled", unavailable ? "true" : "false")

      const checkmark = button.querySelector("[data-swatch-check]")
      if (checkmark) checkmark.classList.toggle("hidden", !isSelected)
    })
  }

  updateSelectedLabels() {
    this.selectedValueTargets.forEach(el => {
      const name = el.dataset.attrName
      el.textContent = this.selection[name] || ""
    })
  }

  updatePriceAndStock(variant) {
    // Prix : on supporte plusieurs cibles (prix principal + sticky mobile).
    // On garde le symbole de devise déjà présent à côté pour ne pas le dupliquer
    // dans le sticky où il est en HTML séparé. Pour le prix principal, on
    // inclut le symbole car le markup d'origine le concatène dans le textContent.
    this.priceTargets.forEach(el => {
      if (variant) {
        const includeSymbol = el.dataset.priceWithSymbol !== "false"
        el.textContent = includeSymbol
          ? `${variant.price_formatted} ${this.currencySymbol}`
          : variant.price_formatted
      } else {
        el.textContent = "—"
      }
    })

    this.originalPriceTargets.forEach(el => {
      if (variant && variant.discount > 0 && variant.original_price > variant.price) {
        el.textContent = `${variant.original_price_formatted} ${this.currencySymbol}`
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
      }
    })

    this.stockBadgeTargets.forEach(el => {
      el.classList.remove("hidden")
      if (!variant) {
        el.textContent = "Sélectionnez une combinaison disponible"
        el.className = "text-sm text-gray-500 font-medium"
      } else if (!variant.in_stock) {
        el.textContent = "✗ Rupture de stock"
        el.className = "text-sm text-red-600 font-medium"
      } else if (variant.stock <= 3) {
        el.textContent = `⚠ Plus que ${variant.stock} — commandez vite`
        el.className = "text-sm text-amber-600 font-medium"
      } else {
        el.textContent = "✓ En stock"
        el.className = "text-sm text-green-600 font-medium"
      }
    })
  }

  updateForm(variant) {
    const usable = variant && variant.in_stock

    if (this.hasVariantInputTarget) {
      this.variantInputTarget.value = variant ? variant.id : ""
    }
    if (this.hasQuantityInputTarget) {
      const input = this.quantityInputTarget
      input.max = variant ? variant.stock : 1
      if (variant && parseInt(input.value, 10) > variant.stock) {
        input.value = variant.stock
      }
      if (parseInt(input.value, 10) < 1) input.value = 1
      if (this.hasQuantityHiddenTarget) {
        this.quantityHiddenTarget.value = input.value
      }
    }

    if (this.hasAddToCartTarget) {
      this.addToCartTarget.disabled = !usable
      this.addToCartTarget.classList.toggle("opacity-50", !usable)
      this.addToCartTarget.classList.toggle("cursor-not-allowed", !usable)
    }
    if (this.hasAddToCartWrapperTarget) {
      this.addToCartWrapperTarget.classList.toggle("hidden", !usable)
    }
    if (this.hasOutOfStockTarget) {
      this.outOfStockTarget.classList.toggle("hidden", usable)
    }
  }

  updateImage(variant) {
    if (!this.hasMainImageTarget || !variant) return
    // Phase 1 : pas d'image par variante en DB. On laisse l'image principale
    // inchangée — les miniatures du carousel restent fonctionnelles. Hook
    // prévu pour la Phase 3 quand les images par couleur seront uploadées.
  }

  updateUrl(variant) {
    if (!variant) return
    const url = new URL(window.location.href)
    if (url.searchParams.get("variant_id") === String(variant.id)) return
    url.searchParams.set("variant_id", variant.id)
    window.history.replaceState({}, "", url.toString())
  }
}
