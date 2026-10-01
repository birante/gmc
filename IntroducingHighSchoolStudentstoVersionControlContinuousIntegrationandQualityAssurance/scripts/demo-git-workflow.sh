#!/usr/bin/env bash
# Demonstrates the full student Git workflow in a THROWAWAY repository:
#   init -> stage -> commit -> "remote" push/pull -> branches -> merge -> real merge conflict -> resolution.
# Everything happens in a temporary directory (mktemp -d), never inside your real project.
#
# Usage:  bash scripts/demo-git-workflow.sh            (prints to the terminal)
#         bash scripts/demo-git-workflow.sh > docs/git-demo-output.txt
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/git-demo.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

step() { printf '\n========== %s ==========\n' "$*"; }
# Print the command (with the temp path shortened to <tmp>), then run it.
run() {
  local cmd="" arg
  for arg in "$@"; do
    case "$arg" in
      *" "* | *"#"*) cmd+=" \"$arg\"" ;;
      *) cmd+=" $arg" ;;
    esac
  done
  printf '$%s\n' "${cmd//$WORK/<tmp>}"
  "$@"
}

# Isolate from the user's global Git config so the demo behaves the same everywhere.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_DATE="2026-10-01T09:00:00Z" GIT_COMMITTER_DATE="2026-10-01T09:00:00Z"

step "0. A shared 'remote' (stands in for GitHub)"
run git init --quiet --bare --initial-branch=main "$WORK/remote.git"
echo "Bare remote created at <tmp>/remote.git"

step "1. Student A: init, stage, commit, push"
mkdir "$WORK/alice" && cd "$WORK/alice"
run git init --quiet --initial-branch=main
git config user.name "Alice (Student A)"
git config user.email "alice@example.com"
cat > grades.js <<'JS'
export function letterGrade(score) {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  return 'C';
}
JS
echo "# Gradebook" > README.md
run git status --short
run git add grades.js README.md
run git commit --quiet -m "Initial commit: letterGrade function"
run git remote add origin "$WORK/remote.git"
run git push --quiet -u origin main
run git log --oneline

step "2. Student B: clone the shared repository"
run git clone --quiet "$WORK/remote.git" "$WORK/bob"
cd "$WORK/bob"
git config user.name "Bob (Student B)"
git config user.email "bob@example.com"
run git log --oneline

step "3. Feature branches developed in isolation"
cd "$WORK/alice"
run git switch --quiet -c feature/add-d-grade
sed -i.bak "s/  return 'C';/  if (score >= 70) return 'C';\n  return 'D';/" grades.js && rm grades.js.bak
run git commit --quiet -am "Add D grade below 70"
run git push --quiet -u origin feature/add-d-grade

cd "$WORK/bob"
run git switch --quiet -c feature/add-f-grade
sed -i.bak "s/  return 'C';/  if (score >= 60) return 'C';\n  return 'F';/" grades.js && rm grades.js.bak
run git commit --quiet -am "Add F grade below 60"
echo "Bob also documents the project." >> README.md
run git commit --quiet -am "Document the project in README"
run git branch -a

step "4. Merge Alice's feature into main (clean merge, like a merged PR)"
cd "$WORK/alice"
run git switch --quiet main
run git merge --no-ff --quiet -m "Merge pull request #1 from feature/add-d-grade" feature/add-d-grade
run git push --quiet origin main
run cat grades.js

step "5. Bob pulls the new main and merges it into his branch -> CONFLICT"
cd "$WORK/bob"
run git switch --quiet main
run git pull --quiet origin main
run git switch --quiet feature/add-f-grade
printf '$ git merge main\n'
if git merge main; then
  echo "Unexpected: no conflict"
  exit 1
fi
run git status --short
echo "--- grades.js with conflict markers ---"
cat grades.js

step "6. Resolve the conflict (keep BOTH ideas: C >= 70, D >= 60, otherwise F)"
cat > grades.js <<'JS'
export function letterGrade(score) {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  if (score >= 60) return 'D';
  return 'F';
}
JS
run cat grades.js
run git add grades.js
run git commit --quiet --no-edit
run git push --quiet -u origin feature/add-f-grade

step "7. Pull request #2 reviewed and merged into main"
run git switch --quiet main
run git merge --no-ff --quiet -m "Merge pull request #2 from feature/add-f-grade" feature/add-f-grade
run git push --quiet origin main
run git branch -d feature/add-f-grade

step "8. Alice pulls the final main"
cd "$WORK/alice"
run git pull --quiet origin main
run git branch -d feature/add-d-grade

step "9. Final history"
run git log --graph --oneline --decorate --all
echo
echo "Demo finished. Temporary directory will be removed."
