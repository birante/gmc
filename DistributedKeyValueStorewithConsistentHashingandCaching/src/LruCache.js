// LRU cache using JS's insertion-ordered Map. On get() we re-insert
// to bump the entry to the "most-recent" end. When capacity is exceeded
// we evict the first (least-recent) entry.

export class LruCache {
  #capacity;
  #store;
  hits = 0;
  misses = 0;

  constructor(capacity = 100) {
    if (capacity <= 0) throw new Error("capacity must be positive");
    this.#capacity = capacity;
    this.#store = new Map();
  }

  get size()     { return this.#store.size; }
  get capacity() { return this.#capacity; }

  get(key) {
    if (!this.#store.has(key)) { this.misses += 1; return null; }
    const value = this.#store.get(key);
    this.#store.delete(key);
    this.#store.set(key, value);   // re-insert to become MRU
    this.hits += 1;
    return value;
  }

  set(key, value) {
    if (this.#store.has(key)) this.#store.delete(key);
    else if (this.#store.size >= this.#capacity) {
      // Evict the oldest entry (first inserted / least recently used).
      const oldestKey = this.#store.keys().next().value;
      this.#store.delete(oldestKey);
    }
    this.#store.set(key, value);
  }

  invalidate(key) { this.#store.delete(key); }
  clear() { this.#store.clear(); this.hits = 0; this.misses = 0; }
}
