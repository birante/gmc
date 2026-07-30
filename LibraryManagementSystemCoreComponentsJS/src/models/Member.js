// Composition over inheritance: a Member has a MembershipPlan that
// carries the varying policy (borrow limit, max active loans, fine rate).
// New member kinds are added by defining a new plan, not a new subclass.

export class MembershipPlan {
  constructor({ name, borrowLimitDays, maxActiveLoans, dailyFineRate }) {
    this.name = name;
    this.borrowLimitDays = borrowLimitDays;
    this.maxActiveLoans = maxActiveLoans;
    this.dailyFineRate = dailyFineRate;
  }
}

export const Plans = Object.freeze({
  STUDENT: new MembershipPlan({
    name: "Student",
    borrowLimitDays: 14,
    maxActiveLoans: 3,
    dailyFineRate: 0.5,
  }),
  TEACHER: new MembershipPlan({
    name: "Teacher",
    borrowLimitDays: 30,
    maxActiveLoans: 10,
    dailyFineRate: 0.25,
  }),
});

export class Member {
  #id;
  #name;
  #email;
  #plan;
  #activeLoanIds;

  constructor({ id, name, email, plan }) {
    this.#id = id;
    this.#name = name;
    this.#email = email;
    this.#plan = plan;
    this.#activeLoanIds = new Set();
  }

  get id()             { return this.#id; }
  get name()           { return this.#name; }
  get email()          { return this.#email; }
  get plan()           { return this.#plan; }
  get activeLoanCount(){ return this.#activeLoanIds.size; }

  canBorrow() {
    return this.#activeLoanIds.size < this.#plan.maxActiveLoans;
  }

  attachLoan(loanId)   { this.#activeLoanIds.add(loanId); }
  detachLoan(loanId)   { this.#activeLoanIds.delete(loanId); }
}
