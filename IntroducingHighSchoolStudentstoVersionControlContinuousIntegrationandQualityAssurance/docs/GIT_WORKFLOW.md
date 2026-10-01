# Git Workflow Lab (Student Guide)

This lab walks you through everything a developer does with Git every day. Work in pairs: **Student A** and **Student B**.
Each step shows the command, what it does, and what you should see.

> Want to see the whole lab run automatically? Run `bash scripts/demo-git-workflow.sh`.
> It replays steps 1-8 in a temporary folder and prints the result. A saved run is in
> [`git-demo-output.txt`](git-demo-output.txt).

---

## 0. One-time setup

```bash
git --version                                   # check Git is installed
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

Create a free GitHub account and (recommended) add an SSH key: _GitHub > Settings > SSH and GPG keys_.

## 1. Initialize a repository (Student A)

```bash
mkdir student-gradebook && cd student-gradebook
git init                 # creates the hidden .git folder: this folder is now a repository
git status               # "No commits yet"
```

## 2. Stage and commit

Git has three areas: **working directory** (your files) -> **staging area** (what goes into the next commit) -> **repository** (saved history).

```bash
echo "# Student Gradebook" > README.md
git status               # README.md is "untracked" (red)
git add README.md        # stage it (green in git status)
git commit -m "Add README"
git log --oneline        # one commit in the history
```

Good commit messages are short, in the imperative: _"Add letter grade function"_, not _"stuff"_.

## 3. Push to a remote (GitHub)

1. On GitHub, click **New repository**, name it `student-gradebook`, do **not** add a README.
2. Connect and push:

```bash
git remote add origin git@github.com:<your-user>/student-gradebook.git
git push -u origin main  # -u remembers origin/main as the default upstream
```

Refresh the GitHub page: your commit is there. Invite Student B: _Settings > Collaborators_.

## 4. Clone and pull (Student B)

```bash
git clone git@github.com:<student-a>/student-gradebook.git
cd student-gradebook
git pull                 # later: download and merge new commits from GitHub
```

Always `git pull` before you start working.

## 5. Branches: work in isolation

`main` must always work. New work happens on a **feature branch**.

```bash
git switch -c feature/letter-grade   # create + switch (older Git: git checkout -b)
git branch                           # * marks the current branch
# ... edit src/grades.js ...
git add src/grades.js
git commit -m "Add letterGrade()"
git push -u origin feature/letter-grade
```

Branch naming: `feature/...`, `fix/...`, `docs/...`.

## 6. Feature-branch workflow with a Pull Request

1. Push your branch (step 5).
2. On GitHub: **Compare & pull request**. Fill in the template (what, why, how tested).
3. CI runs automatically (lint + tests + build). Wait for the green check.
4. Ask your partner to review: **Reviewers** > choose Student B.
5. The reviewer reads the **Files changed** tab, leaves comments on lines, then chooses
   **Comment**, **Approve** or **Request changes** (see the checklist in [`CONTRIBUTING.md`](../CONTRIBUTING.md)).
6. Fix the feedback with new commits on the same branch: the PR updates itself.
7. When approved and green: **Merge pull request**, then **Delete branch**.
8. Everyone updates their local `main`:

```bash
git switch main
git pull
git branch -d feature/letter-grade
```

## 7. Create a merge conflict (on purpose)

A conflict happens when two branches change **the same lines** differently.

Student A:

```bash
git switch -c feature/add-d-grade
# change the last line of letterGrade() to:  if (score >= 70) return 'C'; return 'D';
git commit -am "Add D grade below 70"
git push -u origin feature/add-d-grade      # open PR #1 and merge it on GitHub
```

Student B (at the same time, starting from the old main):

```bash
git switch -c feature/add-f-grade
# change the SAME line to:  if (score >= 60) return 'C'; return 'F';
git commit -am "Add F grade below 60"
git switch main && git pull                 # gets PR #1
git switch feature/add-f-grade
git merge main                              # CONFLICT (content): Merge conflict in grades.js
```

## 8. Resolve the conflict

```bash
git status            # "both modified: grades.js"  (UU in --short mode)
```

Open the file. Git marks both versions:

```text
<<<<<<< HEAD
  if (score >= 60) return 'C';
  return 'F';
=======
  if (score >= 70) return 'C';
  return 'D';
>>>>>>> main
```

- Between `<<<<<<<` and `=======`: **your** branch.
- Between `=======` and `>>>>>>>`: the branch you are merging in.

Decide with your partner what the correct code is (here: keep both ideas), **delete the markers**, then:

```text
  if (score >= 70) return 'C';
  if (score >= 60) return 'D';
  return 'F';
```

```bash
npm test                     # make sure everything still works
git add grades.js            # mark as resolved
git commit                   # Git pre-fills "Merge branch 'main' into feature/add-f-grade"
git push
```

Your PR on GitHub now shows no conflicts and can be reviewed and merged. Stuck? `git merge --abort` returns to the state before the merge.

> Tip: GitHub can also resolve simple conflicts in the browser with the **Resolve conflicts** button on the PR.

## 9. See the history

```bash
git log --graph --oneline --decorate --all
```

Each `*` is a commit, lines show branches splitting and merging. Compare with the final graph in
[`git-demo-output.txt`](git-demo-output.txt).

## Cheat sheet

| Goal                      | Command                                  |
| ------------------------- | ---------------------------------------- |
| What changed?             | `git status`, `git diff`                 |
| Stage / unstage           | `git add <file>`, `git restore --staged` |
| Commit                    | `git commit -m "message"`                |
| Upload / download         | `git push`, `git pull`                   |
| New branch                | `git switch -c <name>`                   |
| Change branch             | `git switch <name>`                      |
| Merge a branch into yours | `git merge <name>`                       |
| Abort a merge             | `git merge --abort`                      |
| Discard changes in a file | `git restore <file>`                     |
| History                   | `git log --oneline --graph --all`        |
