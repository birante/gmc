export class Book {
  #id;
  #title;
  #author;
  #isbn;
  #available;

  constructor(id, title, author, isbn) {
    this.#id = id;
    this.#title = title;
    this.#author = author;
    this.#isbn = isbn;
    this.#available = true;
  }

  get id() { return this.#id; }
  get title() { return this.#title; }
  get author() { return this.#author; }
  get isbn() { return this.#isbn; }
  get isAvailable() { return this.#available; }

  markBorrowed() {
    if (!this.#available) {
      throw new Error(`Book "${this.#title}" is already borrowed.`);
    }
    this.#available = false;
  }

  markReturned() {
    this.#available = true;
  }

  toString() {
    return `"${this.#title}" by ${this.#author} (ISBN: ${this.#isbn})`;
  }
}
