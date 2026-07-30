# Smart Library Management System

Checkpoint project applying **Object-Oriented Design** and design patterns to a small library domain: users, books, and borrowing transactions.

## Run

```bash
node src/index.js
# or
npm start
```

Requires Node.js 16+ (uses ES modules and private class fields).

## Subsystems

| Subsystem          | Responsibility                                                    |
| ------------------ | ----------------------------------------------------------------- |
| User management    | Register `Student` / `Teacher`, expose borrowing rules per role   |
| Book management    | Maintain the catalogue and availability of each `Book`            |
| Borrowing system   | Create, track and close `BorrowTransaction`s, detect overdue ones |
| Notifications      | Push messages to subscribed users (Observer pattern)              |

## Class map

```
User (abstract)
├── Student   (borrow limit: 14 days)
└── Teacher   (borrow limit: 30 days)

Book
BorrowTransaction   (user × book × due date)

UserFactory                 -- Factory Pattern
LibrarySystem  (Singleton)  -- Singleton Pattern
NotificationService         -- Observer Pattern
```

## Design patterns

1. **Singleton — `LibrarySystem`**
   - The whole system uses a single library instance obtained via `LibrarySystem.getInstance()`.
   - The constructor throws if invoked directly after the instance already exists, guaranteeing one and only one central registry.

2. **Factory — `UserFactory`**
   - `UserFactory.createUser("student" | "teacher", { name, email, ... })` centralises user creation, assigns a stable ID and hides the concrete subclass from callers.

3. **Observer — `NotificationService`**
   - Every user added to the library is automatically subscribed.
   - When a book is borrowed, returned, or becomes overdue, the service pushes a `notify()` message to the affected user.
   - Users can `unsubscribe()` at any time.

## OOP principles

- **Abstraction** — `User` is abstract: instantiating it directly throws, and `getRole()` / `getBorrowLimitDays()` are declared but not implemented.
- **Inheritance** — `Student` and `Teacher` extend `User` and provide role-specific borrowing rules.
- **Encapsulation** — all mutable fields are `#private`; the outside world only touches them through getters and behaviour methods (`borrowBook`, `returnBook`, `markReturned`, ...).
- **Polymorphism** — the library treats every user through the `User` API; each subclass returns its own borrow limit, which drives the transaction's due date.

## Features implemented

- Add users (via factory) and books
- Borrow a book — creates a `BorrowTransaction`, marks the book unavailable, computes a role-specific due date
- Return a book — closes the transaction and frees the book
- View a user's currently borrowed books
- Detect overdue transactions and notify their owners (each overdue notification is sent only once, tracked by an `overdueNotified` flag on the transaction)

## Files

```
src/
├── User.js                 abstract base class
├── Student.js              extends User
├── Teacher.js              extends User
├── Book.js
├── BorrowTransaction.js
├── UserFactory.js          Factory pattern
├── NotificationService.js  Observer pattern
├── LibrarySystem.js        Singleton orchestrator
└── index.js                runnable demo
```
