# Introduction to Design Patterns and Procedural Programming

Two implementations of the same shopping cart, side by side:

- **`procedural.js`** — Part 1: pure procedural style (module-level `let cart`, free functions).
- **`module-pattern.js`** — Part 2: same behaviour refactored with the **Module pattern** (IIFE closure that hides the private state and exposes a small public API).

## Run

```bash
npm run procedural   # Part 1 — procedural version
npm run module       # Part 2 — Module pattern version
```

Requires Node.js 14+ (only uses ES modules for the harness; the demos themselves are plain ES5-compatible code).

## Expected output (both files)

```
> viewCart()
Apple (x2) - 3.00 TND
Orange (x3) - 6.00 TND
Total: 9.00 TND

> removeItem("Apple")
> viewCart()
Orange (x3) - 6.00 TND
Total: 6.00 TND
```

The Module version additionally demonstrates that external code cannot reach the private `items` array — an assignment from outside is silently ignored.

## Why the Module pattern?

- It's the most idiomatic JavaScript answer to "hide state" — a closure is the language's native encapsulation mechanism.
- It contrasts cleanly with Part 1: the procedural version keeps state in a `let` that anyone can read or overwrite; the module version puts the exact same state one lexical scope deeper, and suddenly it's unreachable from outside.
- It requires no classes, no `new`, no `this` — perfect fit for a small single-instance store.

Singleton would have worked too (and is arguably a superset of the Module pattern here), but Singleton via `class` introduces `new`/`this` mechanics that add ceremony without adding capability for a cart this simple.

## Deliverables

- `procedural.js` — Part 1 code
- `module-pattern.js` — Part 2 refactor
- `REFLECTION.md` — challenges, benefits, and when to reach for a pattern (~280 words)
