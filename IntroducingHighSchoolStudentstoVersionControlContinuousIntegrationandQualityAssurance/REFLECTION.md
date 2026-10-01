# Reflection

## What challenges did I face while learning Git, CI and QA tools?

The hardest part of Git was understanding the staging area and what a merge conflict really means. The first `<<<<<<< HEAD`
markers looked like a broken file. Producing a conflict on purpose, reading both versions and
deciding with my partner which logic to keep made it clear that Git only shows the disagreement; humans resolve it.
CI had its own surprises: my first test script (`node --test tests/`) failed because Node expected files rather than a
folder, and in a monorepo GitHub Actions only reads workflows from the root, so I needed `paths` filters and a
working directory. ESLint confused me when the Prettier preset silently disabled the `curly` rule.

## How did the CI pipeline help streamline the development process?

The pipeline runs lint, formatting, 58 unit tests with a coverage gate, and a build on Node 20 and 22 for every push.
I no longer need to remember every check, and a red cross appears on the pull request when something breaks. The job summary shows coverage directly on the run page, so nobody has to download reports.
Because the machine answers "does it still work?", review time is spent on design instead.

## How did version control and QA practices improve collaboration and code quality?

Feature branches let my partner and me work at the same time without overwriting each other, and pull requests gave
us a place to discuss changes before they reached `main`. The linter caught seven issues in my first `curveScores`
draft, and the unit tests then exposed two real bugs that were lint-clean. Peer review added edge cases I had
missed, such as an empty list. These habits made our code more reliable and our teamwork calmer.
