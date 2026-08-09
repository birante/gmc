// A storage shard. `alive: false` simulates a crash — reads and writes
// against a dead node throw, so the Cluster can fail over to a replica.

export class Node {
  #id;
  #store;
  #alive;

  constructor(id) {
    this.#id = id;
    this.#store = new Map();
    this.#alive = true;
  }

  get id()    { return this.#id; }
  get alive() { return this.#alive; }
  get size()  { return this.#store.size; }
  keys()      { return [...this.#store.keys()]; }

  fail()      { this.#alive = false; }
  recover()   { this.#alive = true; }

  put(key, value) {
    if (!this.#alive) throw new Error(`node ${this.#id} is down`);
    this.#store.set(key, value);
  }

  get(key) {
    if (!this.#alive) throw new Error(`node ${this.#id} is down`);
    return this.#store.get(key) ?? null;
  }

  delete(key) {
    if (!this.#alive) throw new Error(`node ${this.#id} is down`);
    return this.#store.delete(key);
  }

  // Used by the Cluster to remove entries this node no longer owns
  // (e.g. after a rebalance). Bypasses the alive check because the
  // Cluster only calls this on live nodes.
  _internalDelete(key) { this.#store.delete(key); }
}
