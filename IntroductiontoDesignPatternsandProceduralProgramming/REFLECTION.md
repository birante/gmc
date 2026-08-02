# Reflection — Procedural vs Module Pattern

## What challenges did the refactor bring?

The refactor itself was mechanical, but two small friction points showed up. First, deciding what belonged to the *public surface* and what belonged to the *private helpers*. In the procedural version `viewCart` did the money formatting inline; when I moved to a closure I had to consciously decide whether `format()` and `lineTotal()` should be exposed. Keeping them private meant the public API stays tight (four verbs — `addItem`, `removeItem`, `clearCart`, `viewCart`), which is exactly what encapsulation is for. Second, once the cart was invisible from the outside I had to add a `snapshot()` read-only accessor for tests and debugging — a small tax you pay for hiding state, and a good reminder that "hide everything" can trap you if you don't plan an escape hatch.

## How did the pattern improve the code?

Three concrete gains. **Encapsulation** — the `items` array is no longer reachable, so accidental mutation from elsewhere in a larger program is impossible (the demo tries and fails silently). **Named surface** — instead of a bag of free functions competing for global names, everything lives under one `ShoppingCart` handle, making the code self-documenting. **A natural place for invariants** — the module was the obvious spot to add input validation (`quantity > 0`, `price ≥ 0`) that would have felt out of place scattered across free functions.

## When would I choose a design pattern over procedural code?

For a throwaway script or a single-user CLI, procedural is fine — patterns add ceremony that pays off only when several parts of the program touch the same state. The moment more than one caller needs the cart, the moment the state needs invariants, or the moment the code is imported into a larger project, a pattern (Module, Singleton, Factory…) becomes worth the extra lines because it turns *hopeful discipline* into *enforced boundaries*.

*(Body ≈ 280 words, within the 200–300 target.)*
