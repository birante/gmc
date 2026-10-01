# Contributing

Thanks for helping with the Student Gradebook! This project is a learning playground, so every change goes through the
same steps professional teams use.

## Workflow

1. `git switch main && git pull` - start from the latest code.
2. `git switch -c feature/<short-name>` (or `fix/...`, `docs/...`).
3. Make a **small** change and add/adjust tests in `tests/`.
4. Run the checks locally:
   ```bash
   npm run lint          # ESLint: errors and bad patterns
   npm run format        # Prettier: formats the code for you
   npm test              # unit tests
   npm run build         # syntax check + smoke test
   ```
5. Commit with an imperative message (`Add weighted average`), push, open a Pull Request.
6. Wait for **CI** to be green and for **one approving review**.
7. The author merges (prefer "Create a merge commit" or "Squash and merge"), then deletes the branch.

Never push directly to `main`. (Teachers: enable _Settings > Branches > Branch protection_ on `main` with
"Require a pull request", "Require approvals: 1" and "Require status checks to pass: Build & test".)

## Code review checklist

Use this when reviewing a classmate's PR. Be kind, specific and suggest a fix.

**Correctness**

- [ ] Does the code do what the PR description says?
- [ ] Are edge cases handled (empty list, 0, 100, invalid input)?
- [ ] Do the new tests actually fail if the code is wrong?

**Readability**

- [ ] Are names clear (`studentAverage`, not `sa`)?
- [ ] Are functions short and doing one thing?
- [ ] Are comments explaining _why_, not repeating _what_?

**Quality gates**

- [ ] CI is green (lint, format, tests, build on Node 20 and 22).
- [ ] Coverage did not drop (see the job summary / coverage artifact).
- [ ] No duplicated code, no leftover debug output.

**Collaboration**

- [ ] The PR is small enough to review in 10 minutes.
- [ ] The description explains how it was tested.

### Writing good review comments

| Instead of...      | Write...                                                                         |
| ------------------ | -------------------------------------------------------------------------------- |
| "This is wrong."   | "`== null` also matches `undefined`; could we use `=== null` or validate input?" |
| "Bad name."        | "Could we rename `x` to `bonus` so it is clear what it holds?"                   |
| (silence on a bug) | "What happens if `scores` is empty? `Math.max()` returns `-Infinity` there."     |

Prefix optional ideas with **nit:** so the author knows they are not blocking.
