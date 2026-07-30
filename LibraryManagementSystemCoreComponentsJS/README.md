# Library Management System — Core Components (JS)

Low-Level-Design checkpoint focused on **modularity, reusability and testability** in Node.js. Every component is an ES module, every dependency is injected, and the three design patterns (Factory, Strategy, Observer) are demonstrated end-to-end.

Contrast with the sibling `SmartLibraryManagementSystem/` checkpoint (which uses Singleton and Java-style inheritance): here we use **composition + dependency injection** — no globals, no singletons, testable in isolation.

## Run

```bash
node src/index.js     # demo
node tests/run.js     # unit tests
# or
npm start
npm test
```

Requires Node.js 16+ (uses ES modules and private class fields).

## Project structure

```
src/
├── interfaces/                 -- abstract "contracts" (throw-not-implemented)
│   ├── Repository.js
│   ├── FineStrategy.js
│   ├── SearchStrategy.js
│   └── NotificationChannel.js
├── models/                     -- domain data + local invariants
│   ├── Book.js                 -- with AVAILABLE / ISSUED / RETIRED state machine
│   ├── Member.js               -- has a MembershipPlan (composition, not inheritance)
│   └── Loan.js
├── repositories/
│   └── InMemoryRepository.js   -- generic implementation of Repository
├── strategies/                 -- interchangeable algorithms
│   ├── fineStrategies.js       -- Standard, NoFine
│   ├── searchStrategies.js     -- Title, Author, Isbn, AnyOf (composite)
│   └── notificationChannels.js -- Console, InMemory, Email (stub)
├── factories/
│   └── memberFactory.js        -- Factory pattern
├── services/                   -- business logic, everything DI-ed
│   ├── notificationHub.js      -- Observer pattern (topic × recipient × channels)
│   ├── catalog.js
│   └── loanService.js
├── utils/                      -- reusable helpers
│   ├── logger.js
│   ├── ids.js
│   └── dates.js
├── container.js                -- composition root (DI wiring)
└── index.js                    -- runnable demo

tests/
└── run.js                      -- minimal test runner exercising the pieces
```

## Design patterns

### 1. Factory — `src/factories/memberFactory.js`

Creates a `Member` with the right `MembershipPlan` (Student, Teacher…) without leaking that logic to callers.

```js
const alice = memberFactory.createStudent({ name: "Alice", email: "a@x" });
const fatou = memberFactory.createTeacher({ name: "Fatou", email: "f@x" });
```

New member kinds are added by defining a plan in `models/Member.js` and (optionally) a convenience method on the factory — no consumer code changes.

### 2. Strategy — three different axes

| Axis           | Interface                | Concretes                                                     |
| -------------- | ------------------------ | ------------------------------------------------------------- |
| Fine calc      | `FineStrategy`           | `StandardFineStrategy`, `NoFineStrategy`                      |
| Book search    | `SearchStrategy`         | `TitleSearchStrategy`, `AuthorSearchStrategy`, `IsbnSearchStrategy`, `AnyOfStrategy` (composite) |
| Notif channel  | `NotificationChannel`    | `ConsoleChannel`, `InMemoryChannel`, `EmailChannel` (stub)    |

Strategies are injected via the constructor and can be overridden per call:

```js
catalog.search("Gamma", new AuthorSearchStrategy());
```

### 3. Observer — `src/services/notificationHub.js`

Topic-based pub/sub. Any `NotificationChannel` can subscribe to a topic on behalf of a recipient; every publish fans out to all channels registered for that recipient on that topic.

```js
hub.subscribe(Topics.LOAN_OVERDUE, alice, new ConsoleChannel());
hub.subscribe(Topics.LOAN_OVERDUE, alice, auditLog);   // second channel, same topic
hub.publish(Topics.LOAN_OVERDUE, alice, "please return the book");
```

A misbehaving channel is caught so the fan-out continues.

## Dependency injection

There is **no singleton**. `createContainer(overrides = {})` builds a fully-wired LMS; every slot has a sensible default and can be overridden.

```js
// production
const c = createContainer();

// test with a silent logger and no fines
const c = createContainer({
  logger: new Logger({ enabled: false }),
  fineStrategy: new NoFineStrategy(),
});
```

Because nothing is global, two containers created back-to-back are isolated (asserted in `tests/run.js`), which makes tests trivial to write in parallel.

## Interface-like abstractions

JavaScript has no `interface`, so contracts are declared as abstract base classes whose methods `throw` unless overridden:

```js
export class FineStrategy {
  compute(loan, now) { throw new Error("FineStrategy.compute(...) not implemented"); }
}
```

Concrete strategies `extends FineStrategy` and are structurally compatible with the callers (`LoanService`) — the base class is documentation + a safety net, not a runtime type check.

## What the demo shows (`src/index.js`)

1. **Factory** — students and teacher created without knowing plan details.
2. **Strategy (search)** — 4 different search strategies against the same catalogue.
3. **Observer** — each member subscribed to loan events; overdue events also fan out to a second `InMemoryChannel` used as an audit log.
4. **Strategy (fine)** — standard fine of 7.50 assessed on Alice's 15-day-late return, following her `Plans.STUDENT.dailyFineRate`.
5. **DI** — everything wired in `container.js`; no imports of concrete classes inside services.

## Tests (`tests/run.js`)

Six small tests, each with its own container, cover:

- Factory produces the right plans and unique IDs
- Borrow rejects when the book is unavailable
- Fine strategy is honestly swappable (`NoFineStrategy` waives every fine)
- Standard fine scales by days-overdue × plan rate
- Observer delivers to every subscribed channel
- Two containers are fully isolated (no shared state)

All six pass on `npm test`.
