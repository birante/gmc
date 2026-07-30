# CleanKart — Refactor & Iterate an Online Shopping Cart

Low-Level-Design checkpoint on **refactoring techniques and iterative development**. Starts from a deliberately-messy prototype, walks through four iterations of clean-up and pattern introduction, and ends with a modular, tested codebase.

## Layout

```
CleanKartRefactorIterateanOnlineShoppingCart/
├── v0-messy/
│   └── shop.js          -- the intentionally-bad starter (do not edit)
├── final/
│   ├── src/
│   │   ├── models/Product.js
│   │   ├── builders/ProductBuilder.js         -- Builder pattern
│   │   ├── strategies/discountStrategies.js   -- Strategy pattern
│   │   ├── observers/priceMonitor.js          -- Observer pattern
│   │   ├── cart/{Cart,CartItem}.js
│   │   ├── services/CheckoutService.js
│   │   ├── utils/constants.js
│   │   └── index.js                            -- demo
│   └── tests/run.js                            -- 10 unit tests
├── REPORT.md            -- iteration-by-iteration writeup (read this)
└── README.md
```

## Run

```bash
npm run messy    # run the messy v0 version
npm start        # run the refactored demo (same output, cleaner code)
npm test         # run the 10 unit tests
```

Requires Node.js 16+ (uses ES modules and private class fields).

## Iteration summary

| Iteration                    | Focus                                    | Files touched                                          |
| ---------------------------- | ---------------------------------------- | ------------------------------------------------------ |
| 0 — starting mess            | Baseline (10 documented code smells)     | `v0-messy/shop.js`                                     |
| 1 — clean code               | Extract, rename, kill globals, options-bag ctors | `models/Product.js`, `cart/*`, `services/CheckoutService.js`, `utils/constants.js` |
| 2 — Strategy                 | Kill the `if/else discount` ladder       | `strategies/discountStrategies.js`, `CartItem.js`      |
| 3 — Observer                 | Turn the `priceDrop` TODO into real pub/sub | `observers/priceMonitor.js`, `Product.updatePrice()` |
| 4 — Builder                  | Fluent, safe Product construction        | `builders/ProductBuilder.js`                           |

The full narrative — code smells found, techniques applied, before/after diffs, patterns explained — is in **[REPORT.md](./REPORT.md)**.

## Verification

- The same demo scenario yields `$64.80` in both `v0-messy` and `final` — behavior preserved through refactoring.
- All 10 unit tests pass on `npm test`.
