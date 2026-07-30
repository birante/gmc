import { BorrowTransaction } from "./BorrowTransaction.js";
import { NotificationService } from "./NotificationService.js";

export class LibrarySystem {
  static #instance = null;

  #users;
  #books;
  #transactions;
  #notificationService;
  #nextTransactionId;

  constructor() {
    if (LibrarySystem.#instance) {
      throw new Error("LibrarySystem is a Singleton — use LibrarySystem.getInstance().");
    }
    this.#users = new Map();
    this.#books = new Map();
    this.#transactions = [];
    this.#notificationService = new NotificationService();
    this.#nextTransactionId = 1;
    LibrarySystem.#instance = this;
  }

  static getInstance() {
    if (!LibrarySystem.#instance) {
      new LibrarySystem();
    }
    return LibrarySystem.#instance;
  }

  get notificationService() { return this.#notificationService; }

  addUser(user) {
    if (this.#users.has(user.id)) {
      throw new Error(`User ${user.id} is already registered.`);
    }
    this.#users.set(user.id, user);
    this.#notificationService.subscribe(user);
    return user;
  }

  addBook(book) {
    if (this.#books.has(book.id)) {
      throw new Error(`Book ${book.id} is already in the catalogue.`);
    }
    this.#books.set(book.id, book);
    return book;
  }

  listUsers() { return [...this.#users.values()]; }
  listBooks() { return [...this.#books.values()]; }
  listTransactions() { return [...this.#transactions]; }

  findUser(userId) {
    const user = this.#users.get(userId);
    if (!user) throw new Error(`Unknown user: ${userId}`);
    return user;
  }

  findBook(bookId) {
    const book = this.#books.get(bookId);
    if (!book) throw new Error(`Unknown book: ${bookId}`);
    return book;
  }

  borrowBook(userId, bookId, borrowDate = new Date()) {
    const user = this.findUser(userId);
    const book = this.findBook(bookId);
    book.markBorrowed();
    const id = `T-${String(this.#nextTransactionId++).padStart(4, "0")}`;
    const transaction = new BorrowTransaction(id, user, book, borrowDate);
    user.addBorrowed(transaction);
    this.#transactions.push(transaction);
    this.#notificationService.notify(
      user,
      `You borrowed ${book.toString()}. Due on ${transaction.dueDate.toDateString()}.`
    );
    return transaction;
  }

  returnBook(transactionId, returnDate = new Date()) {
    const transaction = this.#transactions.find(t => t.id === transactionId);
    if (!transaction) throw new Error(`Unknown transaction: ${transactionId}`);
    if (transaction.isReturned) throw new Error(`Transaction ${transactionId} is already closed.`);
    transaction.markReturned(returnDate);
    transaction.book.markReturned();
    transaction.user.removeBorrowed(transaction);
    this.#notificationService.notify(
      transaction.user,
      `Thanks for returning ${transaction.book.toString()}.`
    );
    return transaction;
  }

  viewBorrowedBooks(userId) {
    return this.findUser(userId).borrowedBooks;
  }

  viewBorrowedTransactions(userId) {
    return this.findUser(userId).borrowedTransactions;
  }

  checkOverdue(now = new Date()) {
    const overdue = [];
    for (const t of this.#transactions) {
      if (t.isOverdue(now)) {
        overdue.push(t);
        if (!t.overdueNotified) {
          const delivered = this.#notificationService.notify(
            t.user,
            `OVERDUE: ${t.book.toString()} was due on ${t.dueDate.toDateString()}. Please return it.`
          );
          if (delivered) t.markOverdueNotified();
        }
      }
    }
    return overdue;
  }

  static _resetForTests() {
    LibrarySystem.#instance = null;
  }
}
