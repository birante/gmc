# Weather App — Network Requests in JavaScript

A small weather app that fetches live conditions from a public API and updates the page dynamically. Vanilla HTML + CSS + JS — no build step, no dependencies.

## Run

Open `index.html` in a browser:

```bash
open index.html          # macOS
xdg-open index.html      # Linux
# or double-click the file in your file explorer
```

You can also serve it via any local static server (some browsers restrict `fetch()` on `file://`):

```bash
python3 -m http.server 8000
# then visit http://localhost:8000
```

## API

- Provider: **[Open-Meteo](https://open-meteo.com)** — free, no API key required, no signup.
- Two endpoints are called per search:
  1. **Geocoding** — `https://geocoding-api.open-meteo.com/v1/search?name=…` turns a city name into `latitude`, `longitude`, `country`, `timezone`.
  2. **Forecast** — `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=…` returns the current conditions at those coordinates.

The response's `current.weather_code` follows the **WMO** convention (0 = clear, 3 = overcast, 61-65 = rain, 71-77 = snow, 95-99 = thunderstorm…). `script.js` maps every code to a human label and a background category.

## Files

```
index.html   -- structure, links to styles.css and script.js
styles.css   -- responsive card layout, gradient palette per weather category, dark scheme
script.js    -- fetch geocoding → fetch forecast → render
```

## Features

- Search by city name, results pushed into the DOM.
- Full error handling: geocoding miss, non-2xx responses, network errors — each surfaces a friendly message in the status area.
- Loading state (input + button disabled, "Fetching weather…" banner).
- Background gradient changes to match the weather (clear / cloudy / rain / snow / thunder / fog).
- Responsive: single-column layout under 480 px, side-by-side above.
- Follows `prefers-color-scheme: dark` for a night-friendly theme.
- Accessible: `role="status"`, `aria-live`, visually-hidden label on the input.

## What each part does

**`index.html`** — semantic markup with unique IDs for the pieces of information JS will populate. Two visible sections (`#status` for loading/error, `#result` for the actual weather); one is shown at a time.

**`styles.css`** — CSS custom-property-free (kept simple) but structured with BEM-ish class names, tokenised colours by `[data-condition]`, and one media query per breakpoint + `prefers-color-scheme`.

**`script.js`** — one IIFE, no globals leak. Three phases:
1. `geocodeCity(city)` — resolves the city name to coordinates + timezone.
2. `fetchForecast(coords)` — asks Open-Meteo for the current values we care about.
3. `render(place, forecast)` — pushes the values into the DOM and switches the background category.

The `WEATHER_CODES` map centralises everything about a WMO code so adding a nicer label or a new background category is a one-line change.

## Try these cities

- `Dakar` (auto-loaded on first launch)
- `Paris`, `Tokyo`, `Reykjavik` (varied climates)
- `São Paulo`, `Cape Town`, `Ushuaia` (Southern Hemisphere test)
- Typos to see the error state: `Xyzabc`
