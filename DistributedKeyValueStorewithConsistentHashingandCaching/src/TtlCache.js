// Cache with per-entry TTL. Expired entries are removed lazily on
// access (no background sweeper — keeps the simulation deterministic).

export class TtlCache {
  #store;   // key -> { value, expiresAt }
  hits = 0;
  misses = 0;

  constructor() {
    this.#store = new Map();
  }

  get size() { return this.#store.size; }

  set(key, value, ttlMs) {
    if (typeof ttlMs !== "number" || ttlMs <= 0) {
      throw new Error("ttlMs must be a positive number");
    }
    this.#store.set(key, { value, expiresAt: Date.now() + ttlMs });
  }

  get(key) {
    const entry = this.#store.get(key);
    if (!entry) { this.misses += 1; return null; }
    if (entry.expiresAt < Date.now()) {
      this.#store.delete(key);
      this.misses += 1;
      return null;
    }
    this.hits += 1;
    return entry.value;
  }

  invalidate(key) { this.#store.delete(key); }
  clear() { this.#store.clear(); this.hits = 0; this.misses = 0; }
}
