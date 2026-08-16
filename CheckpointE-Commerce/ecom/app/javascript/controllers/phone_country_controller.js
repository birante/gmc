import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "dropdown", "search", "list", "hidden", "phoneInput"]
  static values = {
    countries: Array,
    selected: String,
    phoneCode: String
  }

  connect() {
    this.filteredCountries = this.countriesValue
    this.selectedCountry = this.countriesValue.find(c => c.code === this.selectedValue) || this.countriesValue[0]
    this.updateDisplay()
    this.renderCountries()
    
    // Fermer le dropdown si on clique ailleurs
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside)
  }

  toggle() {
    this.dropdownTarget.classList.toggle('hidden')
    if (!this.dropdownTarget.classList.contains('hidden')) {
      this.searchTarget.focus()
    }
  }

  search() {
    const query = this.searchTarget.value.toLowerCase()
    this.filteredCountries = this.countriesValue.filter(country => 
      country.name.toLowerCase().includes(query) ||
      country.code.toLowerCase().includes(query) ||
      country.phoneCode.includes(query)
    )
    this.renderCountries()
  }

  selectCountry(event) {
    const countryCode = event.currentTarget.dataset.countryCode
    this.selectedCountry = this.countriesValue.find(c => c.code === countryCode)
    this.selectedValue = countryCode
    this.phoneCodeValue = this.selectedCountry.phoneCode
    this.hiddenTarget.value = countryCode
    this.updateDisplay()
    this.dropdownTarget.classList.add('hidden')
    this.searchTarget.value = ''
    this.filteredCountries = this.countriesValue
    this.renderCountries()
    
    // Focus sur le champ téléphone
    if (this.hasPhoneInputTarget) {
      this.phoneInputTarget.focus()
    }
  }

  updateDisplay() {
    if (this.selectedCountry) {
      const flag = this.getCountryFlag(this.selectedCountry.code)
      this.buttonTarget.innerHTML = `
        <span class="text-xl">${flag}</span>
        <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
        </svg>
        <span class="text-sm font-medium">${this.selectedCountry.phoneCode}</span>
      `
    }
  }

  renderCountries() {
    this.listTarget.innerHTML = this.filteredCountries.map(country => {
      const flag = this.getCountryFlag(country.code)
      const isSelected = country.code === this.selectedValue
      return `
        <div 
          data-action="click->phone-country#selectCountry"
          data-country-code="${country.code}"
          class="flex items-center gap-3 px-4 py-2 hover:bg-gray-50 cursor-pointer ${isSelected ? 'bg-purple-50' : ''}"
        >
          <span class="text-xl">${flag}</span>
          <span class="flex-1 text-sm">${country.name}</span>
          <span class="text-sm text-gray-500">${country.phoneCode}</span>
        </div>
      `
    }).join('')
  }

  getCountryFlag(countryCode) {
    // Convertir le code pays en emoji drapeau
    const codePoints = countryCode
      .toUpperCase()
      .split('')
      .map(char => 127397 + char.charCodeAt())
    return String.fromCodePoint(...codePoints)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target) && !this.dropdownTarget.classList.contains('hidden')) {
      this.dropdownTarget.classList.add('hidden')
      this.searchTarget.value = ''
      this.filteredCountries = this.countriesValue
      this.renderCountries()
    }
  }
}

