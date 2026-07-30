export class BorrowTransaction {
  #id;
  #user;
  #book;
  #borrowDate;
  #dueDate;
  #returnDate;
  #overdueNotified;

  constructor(id, user, book, borrowDate = new Date()) {
    this.#id = id;
    this.#user = user;
    this.#book = book;
    this.#borrowDate = borrowDate;
    const due = new Date(borrowDate);
    due.setDate(due.getDate() + user.getBorrowLimitDays());
    this.#dueDate = due;
    this.#returnDate = null;
    this.#overdueNotified = false;
  }

  get id() { return this.#id; }
  get user() { return this.#user; }
  get book() { return this.#book; }
  get borrowDate() { return this.#borrowDate; }
  get dueDate() { return this.#dueDate; }
  get returnDate() { return this.#returnDate; }
  get isReturned() { return this.#returnDate !== null; }
  get overdueNotified() { return this.#overdueNotified; }

  markReturned(date = new Date()) {
    this.#returnDate = date;
  }

  markOverdueNotified() {
    this.#overdueNotified = true;
  }

  isOverdue(now = new Date()) {
    return !this.isReturned && now > this.#dueDate;
  }
}
