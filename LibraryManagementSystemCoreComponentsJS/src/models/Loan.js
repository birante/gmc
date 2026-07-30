import { addDays } from "../utils/dates.js";

export const LoanStatus = Object.freeze({
  ACTIVE:   "ACTIVE",
  RETURNED: "RETURNED",
});

export class Loan {
  #id;
  #memberId;
  #bookId;
  #borrowDate;
  #dueDate;
  #returnDate;
  #status;
  #fineAmount;

  constructor({ id, memberId, bookId, borrowDate, borrowLimitDays }) {
    this.#id = id;
    this.#memberId = memberId;
    this.#bookId = bookId;
    this.#borrowDate = borrowDate;
    this.#dueDate = addDays(borrowDate, borrowLimitDays);
    this.#returnDate = null;
    this.#status = LoanStatus.ACTIVE;
    this.#fineAmount = 0;
  }

  get id()         { return this.#id; }
  get memberId()   { return this.#memberId; }
  get bookId()     { return this.#bookId; }
  get borrowDate() { return this.#borrowDate; }
  get dueDate()    { return this.#dueDate; }
  get returnDate() { return this.#returnDate; }
  get status()     { return this.#status; }
  get fineAmount() { return this.#fineAmount; }
  get isActive()   { return this.#status === LoanStatus.ACTIVE; }

  isOverdue(now) {
    return this.isActive && now.getTime() > this.#dueDate.getTime();
  }

  close(returnDate, fineAmount = 0) {
    if (!this.isActive) {
      throw new Error(`Loan ${this.#id} is already closed.`);
    }
    this.#returnDate = returnDate;
    this.#status = LoanStatus.RETURNED;
    this.#fineAmount = fineAmount;
  }
}
