// Loan orchestration. Enforces borrow/return rules, delegates fine
// calculation to a Strategy, publishes events through the Observer hub.
// Every collaborator is injected — no globals, no Singleton.

import { Loan } from "../models/Loan.js";
import { Topics } from "./notificationHub.js";

export class LoanService {
  #loanRepo;
  #bookRepo;
  #memberRepo;
  #loanIds;
  #fineStrategy;
  #hub;
  #logger;

  constructor({ loanRepo, bookRepo, memberRepo, loanIds, fineStrategy, hub, logger }) {
    if (!loanRepo)     throw new Error("LoanService requires loanRepo.");
    if (!bookRepo)     throw new Error("LoanService requires bookRepo.");
    if (!memberRepo)   throw new Error("LoanService requires memberRepo.");
    if (!loanIds)      throw new Error("LoanService requires loanIds.");
    if (!fineStrategy) throw new Error("LoanService requires fineStrategy.");
    if (!hub)          throw new Error("LoanService requires notification hub.");
    this.#loanRepo = loanRepo;
    this.#bookRepo = bookRepo;
    this.#memberRepo = memberRepo;
    this.#loanIds = loanIds;
    this.#fineStrategy = fineStrategy;
    this.#hub = hub;
    this.#logger = logger;
  }

  borrow(memberId, bookId, borrowDate = new Date()) {
    const member = this.#requireMember(memberId);
    const book   = this.#requireBook(bookId);
    if (!book.isAvailable) throw new Error(`Book ${bookId} is not available.`);
    if (!member.canBorrow()) {
      throw new Error(`Member ${memberId} reached the borrow limit (${member.plan.maxActiveLoans}).`);
    }

    const loan = new Loan({
      id: this.#loanIds.nextId(),
      memberId, bookId, borrowDate,
      borrowLimitDays: member.plan.borrowLimitDays,
    });

    book.markIssued();
    member.attachLoan(loan.id);
    this.#loanRepo.save(loan);
    this.#logger?.info(`Loan ${loan.id} opened: ${member.name} borrowed ${book.toString()}.`);
    this.#hub.publish(
      Topics.LOAN_CREATED,
      member,
      `You borrowed ${book.toString()}. Due on ${loan.dueDate.toDateString()}.`
    );
    return loan;
  }

  returnBook(loanId, returnDate = new Date()) {
    const loan = this.#loanRepo.findById(loanId);
    if (!loan) throw new Error(`Unknown loan: ${loanId}`);
    if (!loan.isActive) throw new Error(`Loan ${loanId} already closed.`);

    const member = this.#requireMember(loan.memberId);
    const book   = this.#requireBook(loan.bookId);
    const fine   = this.#fineStrategy.compute(loan, returnDate);

    loan.close(returnDate, fine);
    book.markReturned();
    member.detachLoan(loan.id);
    this.#logger?.info(`Loan ${loan.id} closed with fine=${fine}.`);
    this.#hub.publish(Topics.LOAN_RETURNED, member, `Returned ${book.toString()}.`);
    if (fine > 0) {
      this.#hub.publish(Topics.FINE_ISSUED, member, `Fine issued: ${fine.toFixed(2)}.`);
    }
    return { loan, fine };
  }

  checkOverdue(now = new Date()) {
    const overdue = [];
    for (const loan of this.#loanRepo.findAll()) {
      if (!loan.isOverdue(now)) continue;
      overdue.push(loan);
      const member = this.#memberRepo.findById(loan.memberId);
      const book   = this.#bookRepo.findById(loan.bookId);
      if (member) {
        this.#hub.publish(
          Topics.LOAN_OVERDUE,
          member,
          `OVERDUE: ${book?.toString() ?? loan.bookId} was due on ${loan.dueDate.toDateString()}.`
        );
      }
    }
    return overdue;
  }

  #requireMember(id) {
    const m = this.#memberRepo.findById(id);
    if (!m) throw new Error(`Unknown member: ${id}`);
    return m;
  }

  #requireBook(id) {
    const b = this.#bookRepo.findById(id);
    if (!b) throw new Error(`Unknown book: ${id}`);
    return b;
  }
}
