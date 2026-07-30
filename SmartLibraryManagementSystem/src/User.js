export class User {
  #id;
  #name;
  #email;
  #borrowed;

  constructor(id, name, email) {
    if (new.target === User) {
      throw new Error("User is abstract and cannot be instantiated directly. Use Student or Teacher.");
    }
    this.#id = id;
    this.#name = name;
    this.#email = email;
    this.#borrowed = [];
  }

  get id() { return this.#id; }
  get name() { return this.#name; }
  get email() { return this.#email; }
  get borrowedTransactions() { return [...this.#borrowed]; }
  get borrowedBooks() { return this.#borrowed.map(t => t.book); }

  addBorrowed(transaction) {
    this.#borrowed.push(transaction);
  }

  removeBorrowed(transaction) {
    this.#borrowed = this.#borrowed.filter(t => t !== transaction);
  }

  getRole() {
    throw new Error("getRole() must be implemented by subclasses.");
  }

  getBorrowLimitDays() {
    throw new Error("getBorrowLimitDays() must be implemented by subclasses.");
  }

  notify(message) {
    console.log(`[Notification -> ${this.getRole()} ${this.#name} <${this.#email}>] ${message}`);
  }
}
