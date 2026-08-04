// Shared helpers used across the tasks.
// Kept dependency-free so everything runs offline.

export function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Fake API — resolves after ~500 ms with a canned payload, or rejects if
// asked to. Lets tasks 2-5 exercise real async behaviour without touching
// the network.
export function fakeFetch(url, { shouldFail = false, delayMs = 500 } = {}) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      if (shouldFail) reject(new Error(`Network error on ${url}`));
      else            resolve({ url, data: { message: `payload from ${url}` } });
    }, delayMs);
  });
}
