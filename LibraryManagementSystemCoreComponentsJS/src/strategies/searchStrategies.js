// Concrete SearchStrategy implementations. Case-insensitive substring
// match on the chosen field; ISBN match is exact after normalization.

import { SearchStrategy } from "../interfaces/SearchStrategy.js";

class SubstringStrategy extends SearchStrategy {
  constructor(field) {
    super();
    this.field = field;
  }
  matches(book, query) {
    if (!query) return false;
    return String(book[this.field] ?? "").toLowerCase().includes(String(query).toLowerCase());
  }
}

export class TitleSearchStrategy  extends SubstringStrategy { constructor() { super("title");  } }
export class AuthorSearchStrategy extends SubstringStrategy { constructor() { super("author"); } }

export class IsbnSearchStrategy extends SearchStrategy {
  #normalize(v) { return String(v ?? "").replace(/[-\s]/g, ""); }
  matches(book, query) {
    return this.#normalize(book.isbn) === this.#normalize(query);
  }
}

// Composite: match if ANY sub-strategy matches. Handy for a global search bar.
export class AnyOfStrategy extends SearchStrategy {
  #strategies;
  constructor(strategies) { super(); this.#strategies = strategies; }
  matches(book, query) {
    return this.#strategies.some(s => s.matches(book, query));
  }
}
