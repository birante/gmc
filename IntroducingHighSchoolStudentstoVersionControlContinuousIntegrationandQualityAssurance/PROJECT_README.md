# Student Gradebook - Git, CI & QA practice project

[![CI](https://github.com/birante/gmc/actions/workflows/highschool-ci.yml/badge.svg)](https://github.com/birante/gmc/actions/workflows/highschool-ci.yml)

A small, beginner-friendly JavaScript project (Node.js 22, no runtime dependencies) used to teach high-school students
**version control**, **continuous integration** and **quality assurance**.

> `Readme.md` in this folder is the original assignment and is left untouched. This file is the project README
> (macOS file systems are case-insensitive, so `README.md` and `Readme.md` cannot coexist here).

## What the program does

It manages the grades of one class: add students and scores, compute averages (simple and weighted), convert to letter
grades (A-F), rank students, compute the pass rate, "curve" scores, and print a report.

```text
$ npm start
Class: Grade 10 - Computer Science
Students: 4
Class average: 76.08
Pass rate: 75%

#   Name      Avg     Grade  Status
--------------------------------------
1   Awa        91.67  A      PASS
2   Ibrahima   84.33  B      PASS
3   Moussa     72.33  C      PASS
4   Fatou      56.00  F      FAIL
```

Use your own class file: `npm start -- path/to/class.json` (add `--json` for JSON output). Format:
`{ "className": "...", "students": { "Name": [90, 85] } }` - see `data/sample-class.json`.

## Getting started

```bash
nvm use            # Node 22 (see .nvmrc); Node 20 also works
npm ci             # install dev tools (ESLint, Prettier, c8)
npm start
```

## Scripts

| Script                              | What it does                                                               |
| ----------------------------------- | -------------------------------------------------------------------------- |
| `npm start`                         | Prints the report for `data/sample-class.json`                             |
| `npm test`                          | Runs the unit tests with Node's built-in test runner                       |
| `npm run test:coverage`             | Tests + coverage report (fails under 90 % lines/functions, 85 % branches)  |
| `npm run lint`                      | ESLint (flat config in `eslint.config.js`)                                 |
| `npm run lint:fix`                  | ESLint with automatic fixes                                                |
| `npm run format`                    | Formats every file with Prettier (`format:check` only checks)              |
| `npm run build`                     | `node --check` on every source file, CLI smoke test, copies to `dist/`     |
| `bash scripts/demo-git-workflow.sh` | Replays the full Git lab (branches, conflict, resolution) in a temp folder |

## Project structure

```text
src/
  grades.js        pure helpers: validateScore, average, weightedAverage, letterGrade, isPassing
  gradebook.js     Gradebook class: students, scores, averages, ranking, report, fromJSON
  curve.js         curveScores()
  format.js        text table for a report
  cli.js           command-line entry point
tests/             58 unit tests (node:test), 100 % coverage
scripts/
  build.js                build step
  demo-git-workflow.sh    automated Git lab
data/sample-class.json
docs/
  GIT_WORKFLOW.md         step-by-step Git lab for students
  git-demo-output.txt     real output of the demo script (merge conflict + resolution)
  QA_REPORT.md            unit tests, linter findings, code review summary
.github/
  workflows/ci.yml        CI pipeline (used when this folder is its own repository)
  pull_request_template.md
CONTRIBUTING.md           workflow + code review checklist
REFLECTION.md             200-300 word reflection
SUBMISSION.md             deliverables and submission steps
```

## Continuous integration

On every push and pull request GitHub Actions runs, on **Node 20 and 22**:
`npm ci` -> `npm run lint` -> `npm run format:check` -> `npm run test:coverage` -> `npm run build`,
then uploads the coverage report as an artifact and writes a summary (result + coverage) on the run page.

Notifications: GitHub marks each commit/PR with a pass/fail check and emails the author when a run fails. Optional chat
messages are sent if a `SLACK_WEBHOOK_URL` or `DISCORD_WEBHOOK_URL` repository secret exists.

Inside the `birante/gmc` monorepo the same pipeline lives at the repository root in
`.github/workflows/highschool-ci.yml` (GitHub only reads workflows from the root); it only triggers when files in this
folder change.

## Documentation

- [Git workflow lab](docs/GIT_WORKFLOW.md)
- [QA report](docs/QA_REPORT.md)
- [Contributing & review checklist](CONTRIBUTING.md)
- [Reflection](REFLECTION.md)
- [Submission guide](SUBMISSION.md)
