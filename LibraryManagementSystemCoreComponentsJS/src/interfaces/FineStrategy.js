// Strategy: how to compute the fine for a (possibly overdue) loan.
// Return a non-negative number in the library's currency unit.

export class FineStrategy {
  compute(loan, now) {
    throw new Error("FineStrategy.compute(loan, now) not implemented");
  }
}
