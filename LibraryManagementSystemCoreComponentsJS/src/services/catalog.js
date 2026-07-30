// Book catalogue service. Depends on a Repository (interface) and a
// default SearchStrategy (interface) — both injected. Callers may
// override the strategy per query.

export class Catalog {
  #bookRepo;
  #defaultSearch;

  constructor({ bookRepo, defaultSearch }) {
    if (!bookRepo)      throw new Error("Catalog requires a bookRepo.");
    if (!defaultSearch) throw new Error("Catalog requires a defaultSearch strategy.");
    this.#bookRepo = bookRepo;
    this.#defaultSearch = defaultSearch;
  }

  addBook(book)      { return this.#bookRepo.save(book); }
  removeBook(bookId) { return this.#bookRepo.delete(bookId); }
  listBooks()        { return this.#bookRepo.findAll(); }

  search(query, strategy = this.#defaultSearch) {
    return this.#bookRepo.findAll().filter(b => strategy.matches(b, query));
  }
}
