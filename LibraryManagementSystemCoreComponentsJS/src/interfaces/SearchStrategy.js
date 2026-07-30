// Strategy: predicate used by Catalog.search to select books that match
// a query. Return true if `book` matches `query`.

export class SearchStrategy {
  matches(book, query) {
    throw new Error("SearchStrategy.matches(book, query) not implemented");
  }
}
