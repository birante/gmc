// Concrete FineStrategy implementations. Swappable via DI.

import { FineStrategy } from "../interfaces/FineStrategy.js";
import { daysBetween } from "../utils/dates.js";

// dailyFineRate * days-overdue, capped. Reads the rate from the member's
// plan so different member kinds naturally get different fines.
export class StandardFineStrategy extends FineStrategy {
  #maxFine;
  #memberLookup;

  constructor(memberLookup, { maxFine = 50 } = {}) {
    super();
    this.#memberLookup = memberLookup;
    this.#maxFine = maxFine;
  }

  compute(loan, now) {
    if (!loan.isOverdue(now)) return 0;
    const overdueDays = daysBetween(loan.dueDate, now);
    const member = this.#memberLookup(loan.memberId);
    const rate = member ? member.plan.dailyFineRate : 0;
    return Math.min(overdueDays * rate, this.#maxFine);
  }
}

// Waives all fines (grace period, promo, tests).
export class NoFineStrategy extends FineStrategy {
  compute() { return 0; }
}
