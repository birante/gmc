import { LibrarySystem } from "./LibrarySystem.js";
import { UserFactory } from "./UserFactory.js";
import { Book } from "./Book.js";

const library = LibrarySystem.getInstance();

const alice = library.addUser(
  UserFactory.createUser("student", { name: "Alice Diop", email: "alice@school.sn", level: "Master" })
);
const bob = library.addUser(
  UserFactory.createUser("student", { name: "Bob Ndiaye", email: "bob@school.sn" })
);
const prof = library.addUser(
  UserFactory.createUser("teacher", { name: "Dr. Fatou Sarr", email: "fatou@school.sn", department: "Computer Science" })
);

const cleanCode = library.addBook(new Book("B-001", "Clean Code", "Robert C. Martin", "9780132350884"));
const dpBook   = library.addBook(new Book("B-002", "Design Patterns", "Gamma et al.", "9780201633610"));
const pragmatic = library.addBook(new Book("B-003", "The Pragmatic Programmer", "Hunt & Thomas", "9780201616224"));

console.log("=== Users ===");
library.listUsers().forEach(u => console.log(`  ${u.id} — ${u.getRole()}: ${u.name} <${u.email}>`));

console.log("\n=== Catalogue ===");
library.listBooks().forEach(b => console.log(`  ${b.id} — ${b.toString()} ${b.isAvailable ? "[available]" : "[borrowed]"}`));

console.log("\n=== Borrowing ===");
const borrowedOn = new Date("2026-07-01");
library.borrowBook(alice.id, cleanCode.id, borrowedOn);
library.borrowBook(prof.id, dpBook.id, borrowedOn);
library.borrowBook(bob.id, pragmatic.id, new Date("2026-07-28"));

console.log("\n=== Alice's borrowed books ===");
library.viewBorrowedBooks(alice.id).forEach(b => console.log(`  ${b.toString()}`));

console.log("\n=== Alice's active transactions ===");
library.viewBorrowedTransactions(alice.id).forEach(t =>
  console.log(`  ${t.id}: ${t.book.toString()} — due ${t.dueDate.toDateString()}`)
);

console.log("\n=== Overdue check (as of today) ===");
const overdue = library.checkOverdue(new Date("2026-07-30"));
console.log(`  ${overdue.length} overdue transaction(s) detected.`);

console.log("\n=== Return a book ===");
const aliceTx = library.viewBorrowedTransactions(alice.id)[0];
library.returnBook(aliceTx.id, new Date("2026-07-30"));

console.log("\n=== Singleton check ===");
const again = LibrarySystem.getInstance();
console.log(`  Same instance? ${library === again}`);
