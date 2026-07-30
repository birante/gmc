// Minimal DI-driven test harness. Each test builds its own container
// with fakes swapped in — no shared state, no globals.

import { createContainer } from "../src/container.js";
import { Book } from "../src/models/Book.js";
import { NoFineStrategy } from "../src/strategies/fineStrategies.js";
import { InMemoryChannel } from "../src/strategies/notificationChannels.js";
import { Topics } from "../src/services/notificationHub.js";
import { Logger } from "../src/utils/logger.js";

let pass = 0, fail = 0;

function test(name, fn) {
  try { fn(); console.log(`  ok   ${name}`); pass++; }
  catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail++; }
}
function eq(a, b, msg = "") {
  if (a !== b) throw new Error(`${msg} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`);
}
function ok(cond, msg = "") { if (!cond) throw new Error(msg || "assertion failed"); }

console.log("\n--- DI + Factory + Strategy + Observer tests ---");

test("factory issues distinct member IDs and correct plans", () => {
  const c = createContainer({ logger: new Logger({ enabled: false }) });
  const s = c.memberFactory.createStudent({ name: "S", email: "s@x" });
  const t = c.memberFactory.createTeacher({ name: "T", email: "t@x" });
  ok(s.id !== t.id, "ids must differ");
  eq(s.plan.name, "Student");
  eq(t.plan.name, "Teacher");
  eq(s.plan.borrowLimitDays, 14);
  eq(t.plan.borrowLimitDays, 30);
});

test("borrow rejects when book unavailable", () => {
  const c = createContainer({ logger: new Logger({ enabled: false }) });
  const m = c.memberFactory.createStudent({ name: "S", email: "s@x" }); c.memberRepo.save(m);
  const b = c.catalog.addBook(new Book({ id: "B1", title: "T", author: "A", isbn: "1" }));
  c.loans.borrow(m.id, b.id, new Date("2026-01-01"));
  try {
    c.loans.borrow(m.id, b.id, new Date("2026-01-02"));
    throw new Error("expected borrow to throw");
  } catch (e) { ok(/not available/.test(e.message), e.message); }
});

test("NoFineStrategy waives fines even when overdue", () => {
  const c = createContainer({ fineStrategy: new NoFineStrategy(), logger: new Logger({ enabled: false }) });
  const m = c.memberFactory.createStudent({ name: "S", email: "s@x" }); c.memberRepo.save(m);
  const b = c.catalog.addBook(new Book({ id: "B1", title: "T", author: "A", isbn: "1" }));
  const loan = c.loans.borrow(m.id, b.id, new Date("2026-01-01"));
  const { fine } = c.loans.returnBook(loan.id, new Date("2026-07-01"));
  eq(fine, 0, "fine must be waived");
});

test("StandardFineStrategy scales fine by days overdue and plan rate", () => {
  const c = createContainer({ logger: new Logger({ enabled: false }) });
  const s = c.memberFactory.createStudent({ name: "S", email: "s@x" }); c.memberRepo.save(s);
  const b = c.catalog.addBook(new Book({ id: "B1", title: "T", author: "A", isbn: "1" }));
  // Borrow on Jan 1 (due Jan 15). Return on Jan 25 -> 10 days overdue * 0.5 = 5
  const loan = c.loans.borrow(s.id, b.id, new Date("2026-01-01"));
  const { fine } = c.loans.returnBook(loan.id, new Date("2026-01-25"));
  eq(fine, 5, "student fine");
});

test("observer routes overdue events to every subscribed channel", () => {
  const c = createContainer({ logger: new Logger({ enabled: false }) });
  const m = c.memberFactory.createStudent({ name: "S", email: "s@x" }); c.memberRepo.save(m);
  const b = c.catalog.addBook(new Book({ id: "B1", title: "T", author: "A", isbn: "1" }));
  const ch1 = new InMemoryChannel();
  const ch2 = new InMemoryChannel();
  c.hub.subscribe(Topics.LOAN_OVERDUE, m, ch1);
  c.hub.subscribe(Topics.LOAN_OVERDUE, m, ch2);
  c.loans.borrow(m.id, b.id, new Date("2026-01-01"));
  c.loans.checkOverdue(new Date("2026-07-01"));
  eq(ch1.sent.length, 1);
  eq(ch2.sent.length, 1);
});

test("two containers are fully isolated", () => {
  const a = createContainer({ logger: new Logger({ enabled: false }) });
  const b = createContainer({ logger: new Logger({ enabled: false }) });
  a.memberRepo.save(a.memberFactory.createStudent({ name: "A", email: "a@x" }));
  eq(a.memberRepo.findAll().length, 1);
  eq(b.memberRepo.findAll().length, 0);
});

console.log(`\n${pass} passed, ${fail} failed.`);
if (fail > 0) process.exit(1);
