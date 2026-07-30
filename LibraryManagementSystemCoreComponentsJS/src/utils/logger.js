// Tiny logger that can be silenced (useful for tests via DI).

export class Logger {
  #enabled;

  constructor({ enabled = true } = {}) {
    this.#enabled = enabled;
  }

  info(message)  { if (this.#enabled) console.log(`[INFO]  ${message}`); }
  warn(message)  { if (this.#enabled) console.warn(`[WARN]  ${message}`); }
  error(message) { if (this.#enabled) console.error(`[ERROR] ${message}`); }
}
