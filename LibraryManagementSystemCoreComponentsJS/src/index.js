// Demo — wires an LMS from the composition root and exercises every
// pattern: Factory (member creation), Strategy (search, fine, notifs),
// Observer (hub topics), DI (everything via the container).

import { createContainer } from "./container.js";
import { Book } from "./models/Book.js";
import {
  AuthorSearchStrategy,
  IsbnSearchStrategy,
  AnyOfStrategy,
  TitleSearchStrategy,
} from "./strategies/searchStrategies.js";
import { ConsoleChannel, InMemoryChannel } from "./strategies/notificationChannels.js";
import { Topics } from "./services/notificationHub.js";

const c = createContainer();

// --- Factory: create members without touching plan wiring
const alice = c.memberFactory.createStudent({ name: "Alice",  email: "alice@edu.sn" });
const bob   = c.memberFactory.createStudent({ name: "Bob",    email: "bob@edu.sn" });
const fatou = c.memberFactory.createTeacher({ name: "Fatou",  email: "fatou@edu.sn" });
[alice, bob, fatou].forEach(m => c.memberRepo.save(m));

// --- Catalogue
const cleanCode = c.catalog.addBook(new Book({ id: "B-001", title: "Clean Code",              author: "Robert C. Martin", isbn: "9780132350884" }));
const dp        = c.catalog.addBook(new Book({ id: "B-002", title: "Design Patterns",         author: "Gamma et al.",     isbn: "9780201633610" }));
const pragmatic = c.catalog.addBook(new Book({ id: "B-003", title: "The Pragmatic Programmer",author: "Hunt & Thomas",    isbn: "9780201616224" }));

// --- Observer: subscribe with different channels per topic
const auditLog = new InMemoryChannel();
const console_ = new ConsoleChannel();
for (const m of [alice, bob, fatou]) {
  c.hub.subscribe(Topics.LOAN_CREATED,  m, console_);
  c.hub.subscribe(Topics.LOAN_RETURNED, m, console_);
  c.hub.subscribe(Topics.LOAN_OVERDUE,  m, console_);
  c.hub.subscribe(Topics.FINE_ISSUED,   m, console_);
  c.hub.subscribe(Topics.LOAN_OVERDUE,  m, auditLog);   // second channel for the same topic
}

// --- Strategy: swap the search strategy per call
console.log("\n=== Search — default (title) ===");
console.log(c.catalog.search("Clean").map(b => b.toString()));

console.log("\n=== Search — by author ===");
console.log(c.catalog.search("Gamma", new AuthorSearchStrategy()).map(b => b.toString()));

console.log("\n=== Search — by ISBN ===");
console.log(c.catalog.search("978-0201-616-224", new IsbnSearchStrategy()).map(b => b.toString()));

console.log("\n=== Search — global (title OR author OR ISBN) ===");
const global = new AnyOfStrategy([new TitleSearchStrategy(), new AuthorSearchStrategy(), new IsbnSearchStrategy()]);
console.log(c.catalog.search("Hunt", global).map(b => b.toString()));

// --- Loan flow (with observer notifications)
console.log("\n=== Borrow ===");
c.loans.borrow(alice.id, cleanCode.id, new Date("2026-07-01"));
c.loans.borrow(fatou.id, dp.id,        new Date("2026-07-01"));

// --- Overdue check + fine assessment via Strategy
console.log("\n=== Overdue check (as of today) ===");
const overdue = c.loans.checkOverdue(new Date("2026-07-30"));
console.log(`  ${overdue.length} overdue.`);

console.log("\n=== Return the overdue loan (fine expected) ===");
const aliceLoan = c.loanRepo.findAll().find(l => l.memberId === alice.id);
const { fine } = c.loans.returnBook(aliceLoan.id, new Date("2026-07-30"));
console.log(`  Fine assessed: ${fine.toFixed(2)}`);

console.log("\n=== Audit-log channel (in-memory) captured ===");
console.log(`  ${auditLog.sent.length} overdue events for ${new Set(auditLog.sent.map(e => e.recipientId)).size} recipient(s).`);
