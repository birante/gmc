# QA Report - Student Gradebook

Date: 2026-10-01 · Runtime: Node.js 22.20.0 (CI also runs Node 20) · Tools: `node:test`, `c8`, ESLint 9 (flat config), Prettier

All results below come from real runs of the project scripts.

## 1. Summary

| Check                     | Command                 | Result                                                             |
| ------------------------- | ----------------------- | ------------------------------------------------------------------ |
| Lint                      | `npm run lint`          | 0 errors, 0 warnings                                               |
| Formatting                | `npm run format:check`  | All matched files use Prettier code style                          |
| Unit tests                | `npm test`              | **58 tests in 16 suites: 58 passed, 0 failed**                     |
| Coverage (gate: 90/85/90) | `npm run test:coverage` | **100 % statements, 100 % branches, 100 % functions, 100 % lines** |
| Build                     | `npm run build`         | 5 files syntax-checked, CLI smoke test OK, `dist/` created         |

## 2. Unit tests written

Test files live in `tests/` and use Node's built-in test runner (`node --test`). Spec-reporter output of the final run:

### `tests/grades.test.js` - pure grade helpers (`src/grades.js`)

| Suite           | Test                                                                                                                   | Result |
| --------------- | ---------------------------------------------------------------------------------------------------------------------- | ------ |
| validateScore   | accepts scores between 0 and 100                                                                                       | pass   |
| validateScore   | rejects values that are not numbers                                                                                    | pass   |
| validateScore   | rejects scores outside 0-100                                                                                           | pass   |
| round           | rounds to 2 decimals by default                                                                                        | pass   |
| round           | supports a custom number of decimals                                                                                   | pass   |
| average         | computes the mean of a list of scores                                                                                  | pass   |
| average         | returns null for an empty list                                                                                         | pass   |
| average         | throws when given something that is not an array                                                                       | pass   |
| average         | throws when the list contains an invalid score                                                                         | pass   |
| weightedAverage | gives more importance to heavier items                                                                                 | pass   |
| weightedAverage | returns null for an empty list                                                                                         | pass   |
| weightedAverage | rejects non-array input                                                                                                | pass   |
| weightedAverage | rejects zero, negative or missing weights                                                                              | pass   |
| letterGrade     | maps 100 to A, 90 to A, 89.99 to B, 80 to B, 79 to C, 70 to C, 69 to D, 60 to D, 59.9 to F, 0 to F (10 boundary tests) | pass   |
| letterGrade     | throws on invalid scores                                                                                               | pass   |
| isPassing       | passes at 60 and above                                                                                                 | pass   |
| isPassing       | fails below 60                                                                                                         | pass   |

### `tests/gradebook.test.js` - the `Gradebook` class (`src/gradebook.js`)

| Suite            | Test                                                                | Result |
| ---------------- | ------------------------------------------------------------------- | ------ |
| constructor      | stores a trimmed class name                                         | pass   |
| constructor      | rejects an empty class name                                         | pass   |
| students         | adds students and supports chaining                                 | pass   |
| students         | refuses duplicate students (after trimming)                         | pass   |
| students         | rejects invalid student names                                       | pass   |
| students         | removes a student                                                   | pass   |
| scores           | records scores for a student                                        | pass   |
| scores           | returns a copy so callers cannot change internal state              | pass   |
| scores           | rejects invalid scores                                              | pass   |
| scores           | throws for unknown students                                         | pass   |
| scores           | computes a student average                                          | pass   |
| scores           | returns null average for a student without scores                   | pass   |
| class statistics | returns null class average and top student when there are no scores | pass   |
| class statistics | averages student averages and ignores students without scores       | pass   |
| class statistics | ranks students by average, breaking ties alphabetically             | pass   |
| report           | builds a full report with letters and pass rate                     | pass   |
| report           | has a null pass rate for an empty class                             | pass   |
| fromJSON         | creates a gradebook from plain data                                 | pass   |
| fromJSON         | rejects malformed data                                              | pass   |
| fromJSON         | propagates invalid scores in the data                               | pass   |

### `tests/curve.test.js` - score curving (`src/curve.js`)

| Suite       | Test                                                 | Result |
| ----------- | ---------------------------------------------------- | ------ |
| curveScores | raises every score so the best becomes 100           | pass   |
| curveScores | leaves scores unchanged when someone already has 100 | pass   |
| curveScores | keeps decimals tidy                                  | pass   |
| curveScores | returns an empty list for an empty input             | pass   |
| curveScores | rejects bad input                                    | pass   |

### `tests/format-cli.test.js` - text output and CLI (`src/format.js`, `src/cli.js`)

| Suite        | Test                                                    | Result |
| ------------ | ------------------------------------------------------- | ------ |
| formatReport | prints a table with PASS/FAIL status                    | pass   |
| formatReport | handles an empty class                                  | pass   |
| cli run()    | prints the sample class by default                      | pass   |
| cli run()    | prints JSON with --json                                 | pass   |
| cli run()    | reads a custom file and reports errors with exit code 1 | pass   |
| cli run()    | reports a missing file                                  | pass   |
| cli run()    | works when executed as a real process                   | pass   |

```text
ℹ tests 58
ℹ suites 16
ℹ pass 58
ℹ fail 0
```

### Coverage (`npm run test:coverage`, c8)

```text
--------------|---------|----------|---------|---------|-------------------
File          | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
--------------|---------|----------|---------|---------|-------------------
All files     |     100 |      100 |     100 |     100 |
 cli.js       |     100 |      100 |     100 |     100 |
 curve.js     |     100 |      100 |     100 |     100 |
 format.js    |     100 |      100 |     100 |     100 |
 gradebook.js |     100 |      100 |     100 |     100 |
 grades.js    |     100 |      100 |     100 |     100 |
--------------|---------|----------|---------|---------|-------------------
```

Totals: 329/329 lines, 108/108 branches, 23/23 functions. The pipeline **fails** if coverage drops below
90 % lines, 90 % functions or 85 % branches (`c8 --check-coverage`). CI uploads the HTML/LCOV report as the
`coverage-node-20` / `coverage-node-22` artifacts.

### Problems the tests caught during development

1. **Broken test command.** The first version of the `test` script was `node --test tests/`. It failed with
   `Error: Cannot find module '.../tests'` (`not ok 1 - tests`), because `node --test` expects files, not a
   directory. Fixed by using `node --test tests/*.test.js`, which works on Node 20 and 22.
2. **Bugs in the first `curveScores()` draft.** After the lint fixes (section 3) the draft was lint-clean but
   still wrong. Running `tests/curve.test.js` against it gave `pass 3, fail 2`:
   ```text
   ✖ keeps decimals tidy
     AssertionError [ERR_ASSERTION]: Expected values to be strictly deep-equal:
     + actual - expected
       [
     +   66.667,
     -   66.67,
         100
       ]
   ✖ rejects bad input
     AssertionError [ERR_ASSERTION]: Missing expected exception (TypeError).
   ```
   `curveScores('90')` did not throw: `Math.max(...'90')` spreads the string into `'9', '0'` and silently
   returns numbers. Fixed by checking `Array.isArray`, validating every score with `validateScore`, and
   rounding with `round()`. Lesson: _a linter checks style and common mistakes, only tests check behaviour._

## 3. Linter issues detected (ESLint + Prettier)

Configuration: `eslint.config.js` (flat config) = `@eslint/js` recommended + `eslint-config-prettier` + project rules
`no-var`, `prefer-const`, `eqeqeq`, `curly`, `no-unused-vars`. Formatting is checked by Prettier (`.prettierrc.json`).

### Round 1 - first draft of `src/curve.js`

```js
import { validateScore, round, MAX_SCORE } from './grades.js';

export function curveScores(scores) {
  var best = Math.max(...scores);
  let bonus = MAX_SCORE - best;
  let result = [];
  for (let i = 0; i < scores.length; i++) {
    if (scores[i] == null) continue;
    result.push(scores[i] + bonus);
  }
  return result;
}
```

Real `npx eslint .` output:

```text
src/curve.js
  1:10  error  'validateScore' is defined but never used          no-unused-vars
  1:25  error  'round' is defined but never used                  no-unused-vars
  5:3   error  Unexpected var, use let or const instead           no-var
  6:7   error  'bonus' is never reassigned. Use 'const' instead   prefer-const
  7:7   error  'result' is never reassigned. Use 'const' instead  prefer-const
  9:19  error  Expected '===' and instead saw '=='                eqeqeq
  9:28  error  Expected { after 'if' condition                    curly

✖ 7 problems (7 errors, 0 warnings)
  4 errors and 0 warnings potentially fixable with the `--fix` option.
```

| Rule             | Why it matters                                                        | Fix                                             |
| ---------------- | --------------------------------------------------------------------- | ----------------------------------------------- |
| `no-unused-vars` | Dead imports hint at forgotten logic (here: validation and rounding!) | Used `validateScore` and `round` in the rewrite |
| `no-var`         | `var` is function-scoped and leaks out of blocks                      | `const best`                                    |
| `prefer-const`   | `const` tells the reader the value never changes                      | `const bonus`, result built with `map()`        |
| `eqeqeq`         | `==` does type coercion (`null == undefined` is `true`)               | Removed the check; input is validated instead   |
| `curly`          | Braceless `if` is easy to break when adding a line                    | Always use `{ }`                                |

Detail: `curly` was silently disabled at first because `eslint-config-prettier` turns it off. The config was
reordered so the project rules come **after** the Prettier preset, and `curly` was reported as expected.

### Round 2 - formatting

The rewrite contained a one-line `if` with double quotes and no semicolon. Real `npx prettier --check .` output:

```text
Checking formatting...
[warn] src/curve.js
[warn] Code style issues found in the above file. Run Prettier with --write to fix.
```

Fixed with `npx prettier --write src/curve.js`. Final run: `All matched files use Prettier code style!` and
`npm run lint` exits with 0 problems. Both checks run in CI, so style problems block a merge.

## 4. Code review summary

Reviews follow the checklist in [`CONTRIBUTING.md`](../CONTRIBUTING.md) and the PR template in
`.github/pull_request_template.md`. Below is the review of the PR that introduced the score curve
(sample comments a peer reviewer left on the branch `feature/curve-scores`).

**PR: "Add curveScores() to raise class scores"** - Reviewer: Student B - Outcome: _Request changes_, then _Approve_

| #   | File / line           | Reviewer comment                                                                                                                        | Type     | Resolution                                                          |
| --- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------- |
| 1   | `src/curve.js:4`      | "CI is red: ESLint reports 7 errors (`no-var`, `prefer-const`, `eqeqeq`, `curly`...). Can you run `npm run lint:fix` and fix the rest?" | blocking | Fixed in commit "Fix lint errors in curveScores"                    |
| 2   | `src/curve.js:1`      | "`validateScore` and `round` are imported but never used. Did you mean to validate the input?"                                          | blocking | Every score is now validated; `RangeError` on bad scores            |
| 3   | `src/curve.js:5`      | "What happens with an empty array? `Math.max()` returns `-Infinity`, so the bonus is `Infinity`."                                       | blocking | Early `return []` + test "returns an empty list for an empty input" |
| 4   | `src/curve.js:9`      | "Do we ever store `null` scores? `validateScore` already refuses them, so this check looks like dead code."                             | question | Check removed                                                       |
| 5   | `tests/curve.test.js` | "Please add a test with decimals; `66.666 + bonus` will print ugly numbers in the report."                                              | blocking | Added "keeps decimals tidy" (it failed until `round()` was used)    |
| 6   | `src/curve.js`        | "nit: a JSDoc comment explaining what curving means would help other students."                                                         | nit      | JSDoc added                                                         |
| 7   | whole PR              | "Nice small PR, and CI is now green on Node 20 and 22. Approved!"                                                                       | praise   | Merged with a merge commit, branch deleted                          |

Other reviews in the project (same process):

- **`feature/gradebook-report`** - reviewer asked for `getScores()` to return a **copy** so callers cannot mutate
  internal state; a test ("returns a copy so callers cannot change internal state") now protects it.
- **`feature/cli`** - reviewer asked that the CLI return an **exit code** instead of calling `process.exit()`, so it
  can be tested; `run()` now returns `0`/`1` and is covered by five tests.
- **`feature/ranking`** - reviewer noticed ties were ordered randomly; ties are now broken alphabetically and tested.

### What the reviews changed

- 4 real bugs found before merge (empty input, string input, missing validation, unrounded output).
- Every reviewer request that changed behaviour came with a new test, so the bug cannot come back.
- Average time from PR to merge stayed short because PRs were small and CI answered "does it work?" automatically,
  letting reviewers focus on design and readability.
