// Sequential ID generator, injectable so tests can substitute a
// deterministic one. Each generator instance is independent.

export class IdGenerator {
  #prefix;
  #next;

  constructor(prefix, start = 1) {
    this.#prefix = prefix;
    this.#next = start;
  }

  nextId() {
    const id = `${this.#prefix}-${String(this.#next).padStart(4, "0")}`;
    this.#next += 1;
    return id;
  }
}
