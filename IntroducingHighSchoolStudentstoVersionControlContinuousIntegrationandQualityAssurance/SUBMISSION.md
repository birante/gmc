# Submission

Checkpoint: _Introducing High School Students to Version Control, Continuous Integration and Quality Assurance_

## Deliverables

| Requirement (Readme.md)       | Where to find it                                                                                                                                                                              |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Project managed with Git      | This folder (Student Gradebook: `src/`, `tests/`, `data/`) - see [PROJECT_README.md](PROJECT_README.md)                                                                                       |
| Branching, merging, conflicts | [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) (student lab), [scripts/demo-git-workflow.sh](scripts/demo-git-workflow.sh), real output in [docs/git-demo-output.txt](docs/git-demo-output.txt) |
| CI pipeline config            | [.github/workflows/ci.yml](.github/workflows/ci.yml) (standalone) and `/.github/workflows/highschool-ci.yml` at the monorepo root (the one that runs on `birante/gmc`)                        |
| Build + tests on every push   | Both workflows: `npm ci`, lint, format check, tests + coverage gate, build; matrix Node 20 / 22                                                                                               |
| Pass/fail notifications       | GitHub status checks + failure e-mails, job summary, optional Slack/Discord webhook secrets                                                                                                   |
| Unit tests                    | [tests/](tests/) - 58 tests, 100 % coverage                                                                                                                                                   |
| Linter                        | ESLint flat config [eslint.config.js](eslint.config.js) + Prettier                                                                                                                            |
| Peer review via pull requests | [.github/pull_request_template.md](.github/pull_request_template.md), checklist in [CONTRIBUTING.md](CONTRIBUTING.md)                                                                         |
| QA report                     | [docs/QA_REPORT.md](docs/QA_REPORT.md)                                                                                                                                                        |
| Reflection (200-300 words)    | [REFLECTION.md](REFLECTION.md) (260 words of answers, 299 including headings)                                                                                                                 |

## Verified locally (Node 22.20.0)

- `npm run lint` - 0 problems
- `npm run format:check` - all files formatted
- `npm test` - 58/58 passing
- `npm run test:coverage` - 100 % statements / branches / functions / lines
- `npm run build` - OK
- `bash scripts/demo-git-workflow.sh` - merge conflict created and resolved, exit code 0

## What you still need to do

1. **Commit and push** (from the monorepo root):
   ```bash
   cd /Users/macbook/Codes/GOMYCODE/gmc
   git switch -c feature/highschool-git-ci-qa
   git add IntroducingHighSchoolStudentstoVersionControlContinuousIntegrationandQualityAssurance .github/workflows/highschool-ci.yml
   git commit -m "Add HighSchool Git/CI/QA checkpoint with CI pipeline"
   git push -u origin feature/highschool-git-ci-qa
   ```
   The push triggers **HighSchool Gradebook CI** in the _Actions_ tab of `birante/gmc`.
2. **Open a pull request** on GitHub (`feature/highschool-git-ci-qa` -> `main`). The PR template is applied
   automatically only from the repository root; copy the content of `.github/pull_request_template.md` into the PR
   description (or also copy the file to `/.github/pull_request_template.md`).
3. Wait for the green checks (Node 20 and Node 22), ask a classmate to **review** using the checklist in
   `CONTRIBUTING.md`, address comments, then **merge**.
4. (Optional) Add a `SLACK_WEBHOOK_URL` or `DISCORD_WEBHOOK_URL` secret in _Settings > Secrets and variables > Actions_
   to get chat notifications; check _GitHub > Settings > Notifications > Actions_ for e-mail alerts.
5. (Optional) To show branching on GitHub itself, follow sections 5-8 of `docs/GIT_WORKFLOW.md` with a partner on a
   standalone copy of this folder (there `.github/workflows/ci.yml` is used as-is).
6. **Submit the link**:
   `https://github.com/birante/gmc/tree/main/IntroducingHighSchoolStudentstoVersionControlContinuousIntegrationandQualityAssurance`
   plus the link to the pull request and to a green Actions run.
