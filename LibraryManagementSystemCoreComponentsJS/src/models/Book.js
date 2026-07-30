// Domain model — no persistence, no orchestration. Encapsulates only
// the invariants of a single book (state transitions).

export const BookState = Object.freeze({
  AVAILABLE: "AVAILABLE",
  ISSUED:    "ISSUED",
  RETIRED:   "RETIRED",
});

export class Book {
  #id;
  #title;
  #author;
  #isbn;
  #state;

  constructor({ id, title, author, isbn }) {
    this.#id = id;
    this.#title = title;
    this.#author = author;
    this.#isbn = isbn;
    this.#state = BookState.AVAILABLE;
  }

  get id()      { return this.#id; }
  get title()   { return this.#title; }
  get author()  { return this.#author; }
  get isbn()    { return this.#isbn; }
  get state()   { return this.#state; }

  get isAvailable() { return this.#state === BookState.AVAILABLE; }

  markIssued() {
    if (this.#state !== BookState.AVAILABLE) {
      throw new Error(`Book ${this.#id} is not available (state=${this.#state}).`);
    }
    this.#state = BookState.ISSUED;
  }

  markReturned() {
    if (this.#state !== BookState.ISSUED) {
      throw new Error(`Book ${this.#id} is not currently issued (state=${this.#state}).`);
    }
    this.#state = BookState.AVAILABLE;
  }

  retire() { this.#state = BookState.RETIRED; }

  toString() {
    return `"${this.#title}" by ${this.#author} (ISBN: ${this.#isbn})`;
  }
}
