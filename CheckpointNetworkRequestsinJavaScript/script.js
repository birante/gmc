// Weather App — Vanilla JS + Fetch API.
// Data source: Open-Meteo (free, no API key required).
//   1) Geocoding endpoint turns "Dakar" into { latitude, longitude, country }.
//   2) Forecast endpoint returns current conditions for those coordinates.
// The response is parsed and pushed into the DOM.

(() => {
  "use strict";

  const GEOCODE_URL  = "https://geocoding-api.open-meteo.com/v1/search";
  const FORECAST_URL = "https://api.open-meteo.com/v1/forecast";

  // --- DOM references ------------------------------------------------------

  const form        = document.getElementById("searchForm");
  const cityInput   = document.getElementById("cityInput");
  const searchBtn   = document.getElementById("searchBtn");
  const statusEl    = document.getElementById("status");
  const resultEl    = document.getElementById("result");
  const locationEl  = document.getElementById("location");
  const timestampEl = document.getElementById("timestamp");
  const tempEl      = document.getElementById("temperature");
  const descEl      = document.getElementById("description");
  const feelsEl     = document.getElementById("feels");
  const humidityEl  = document.getElementById("humidity");
  const windEl      = document.getElementById("wind");
  const precipEl    = document.getElementById("precip");

  // --- WMO code -> human description + background category ---------------
  // See: https://open-meteo.com/en/docs   (Weather variable documentation)

  const WEATHER_CODES = {
    0:  { label: "Clear sky",                  bg: "clear"   },
    1:  { label: "Mainly clear",               bg: "clear"   },
    2:  { label: "Partly cloudy",              bg: "cloudy"  },
    3:  { label: "Overcast",                   bg: "cloudy"  },
    45: { label: "Fog",                        bg: "fog"     },
    48: { label: "Depositing rime fog",        bg: "fog"     },
    51: { label: "Light drizzle",              bg: "rain"    },
    53: { label: "Moderate drizzle",           bg: "rain"    },
    55: { label: "Dense drizzle",              bg: "rain"    },
    56: { label: "Light freezing drizzle",     bg: "rain"    },
    57: { label: "Dense freezing drizzle",     bg: "rain"    },
    61: { label: "Slight rain",                bg: "rain"    },
    63: { label: "Moderate rain",              bg: "rain"    },
    65: { label: "Heavy rain",                 bg: "rain"    },
    66: { label: "Light freezing rain",        bg: "rain"    },
    67: { label: "Heavy freezing rain",        bg: "rain"    },
    71: { label: "Slight snowfall",            bg: "snow"    },
    73: { label: "Moderate snowfall",          bg: "snow"    },
    75: { label: "Heavy snowfall",             bg: "snow"    },
    77: { label: "Snow grains",                bg: "snow"    },
    80: { label: "Slight rain showers",        bg: "rain"    },
    81: { label: "Moderate rain showers",      bg: "rain"    },
    82: { label: "Violent rain showers",       bg: "rain"    },
    85: { label: "Slight snow showers",        bg: "snow"    },
    86: { label: "Heavy snow showers",         bg: "snow"    },
    95: { label: "Thunderstorm",               bg: "thunder" },
    96: { label: "Thunderstorm w/ light hail", bg: "thunder" },
    99: { label: "Thunderstorm w/ heavy hail", bg: "thunder" },
  };

  // --- UI helpers ----------------------------------------------------------

  function showStatus(kind, message) {
    statusEl.textContent = message;
    statusEl.className = `status status--${kind}`;
    statusEl.hidden = false;
    resultEl.hidden = true;
  }

  function hideStatus() {
    statusEl.hidden = true;
    statusEl.className = "status";
    statusEl.textContent = "";
  }

  function setLoading(isLoading) {
    searchBtn.disabled = isLoading;
    cityInput.disabled = isLoading;
    if (isLoading) showStatus("loading", "Fetching weather…");
  }

  function setCondition(category) {
    document.body.dataset.condition = category ?? "clear";
  }

  // --- API calls -----------------------------------------------------------

  async function geocodeCity(city) {
    const url = `${GEOCODE_URL}?name=${encodeURIComponent(city)}&count=1&language=en&format=json`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Geocoding failed (${res.status})`);
    const body = await res.json();
    if (!body.results || body.results.length === 0) {
      const err = new Error(`No match for "${city}". Try a different spelling or a nearby city.`);
      err.code = "NOT_FOUND";
      throw err;
    }
    const r = body.results[0];
    return {
      name: r.name,
      country: r.country,
      admin1: r.admin1,
      latitude: r.latitude,
      longitude: r.longitude,
      timezone: r.timezone,
    };
  }

  async function fetchForecast({ latitude, longitude, timezone }) {
    const params = new URLSearchParams({
      latitude, longitude,
      timezone: timezone ?? "auto",
      current: "temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m",
      wind_speed_unit: "kmh",
      temperature_unit: "celsius",
    });
    const res = await fetch(`${FORECAST_URL}?${params.toString()}`);
    if (!res.ok) throw new Error(`Forecast fetch failed (${res.status})`);
    return res.json();
  }

  // --- Render --------------------------------------------------------------

  function render(place, forecast) {
    const c = forecast.current;
    const meta = WEATHER_CODES[c.weather_code] ?? { label: "Unknown conditions", bg: "clear" };

    locationEl.textContent = [place.name, place.admin1, place.country].filter(Boolean).join(", ");
    timestampEl.textContent = `Observed at ${formatTime(c.time, place.timezone)} local time`;
    tempEl.textContent = Math.round(c.temperature_2m);
    descEl.textContent = meta.label;
    feelsEl.textContent    = `${Math.round(c.apparent_temperature)} °C`;
    humidityEl.textContent = `${c.relative_humidity_2m} %`;
    windEl.textContent     = `${Math.round(c.wind_speed_10m)} km/h`;
    precipEl.textContent   = `${c.precipitation} mm`;

    setCondition(meta.bg);
    hideStatus();
    resultEl.hidden = false;
  }

  function formatTime(iso, timeZone) {
    try {
      return new Intl.DateTimeFormat(undefined, {
        hour: "2-digit", minute: "2-digit", weekday: "short",
        timeZone: timeZone ?? undefined,
      }).format(new Date(iso));
    } catch { return iso; }
  }

  // --- Event handling ------------------------------------------------------

  async function handleSearch(city) {
    const trimmed = city.trim();
    if (trimmed.length < 2) {
      showStatus("error", "Please type at least two characters.");
      return;
    }

    setLoading(true);
    try {
      const place    = await geocodeCity(trimmed);
      const forecast = await fetchForecast(place);
      render(place, forecast);
    } catch (err) {
      console.error(err);
      showStatus("error", err.message || "Something went wrong. Please try again.");
    } finally {
      setLoading(false);
      cityInput.focus();
    }
  }

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    handleSearch(cityInput.value);
  });

  // Pre-fill with a nice default so the app is not empty on first load.
  window.addEventListener("DOMContentLoaded", () => {
    cityInput.value = "Dakar";
    handleSearch(cityInput.value);
  });
})();
