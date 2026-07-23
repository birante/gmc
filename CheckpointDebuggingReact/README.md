# Debugging React with React Developer Tools — Checkpoint

A small React application that was **intentionally bugged**, then
**debugged and fixed** using React Developer Tools.

The final code in this repo is the corrected version. Every bug that
was originally present is documented in
**[`DEBUGGING.md`](./DEBUGGING.md)** with:

- the symptom the user saw,
- how a specific React DevTools tab revealed the root cause,
- the exact code diff that fixed it.

## What the app does

- Displays a user profile card (`UserProfile`)
- Shows a live counter of seconds since page load (`LiveCounter`)
- Lets you add / toggle / delete / filter tasks (`TaskList`, `TaskItem`,
  `AddTaskForm`, `FilterBar`)

Component tree:

```text
<App>
├── <LiveCounter>            useState + useEffect (interval)
├── <UserProfile user={…} />  props destructuring
└── <section>
    ├── <AddTaskForm onAdd={…} />
    ├── <FilterBar filter state={…} onChange={…} />
    └── <TaskList tasks={…} onToggle={…} onDelete={…} >
        └── <TaskItem task={…} onToggle={…} onDelete={…} />
```

## Project structure

```text
CheckpointDebuggingReact/
├── DEBUGGING.md            ← the debugging walkthrough (start here)
├── README.md
├── package.json
└── src/
    ├── App.jsx
    ├── App.css
    ├── main.jsx
    ├── index.css
    └── components/
        ├── UserProfile.jsx
        ├── LiveCounter.jsx
        ├── AddTaskForm.jsx
        ├── FilterBar.jsx
        ├── TaskList.jsx
        └── TaskItem.jsx
```

## Bugs found and fixed (see DEBUGGING.md for full write-ups)

| # | Bug | File | DevTools clue |
|---|---|---|---|
| 1 | Missing `key` prop on mapped list | `TaskList.jsx` | Components tab shows children with no key; console warning |
| 2 | Prop name mismatch (`userInfo` vs `user`) | `UserProfile.jsx` | Components tab shows the *real* prop name in the props panel |
| 3 | Stale closure in `setInterval` | `LiveCounter.jsx` | State frozen at `1` in the Components tab |
| 4 | Missing `useEffect` cleanup | `LiveCounter.jsx` | Profiler flame graph shows exploding render count |
| 5 | Direct state mutation (`.push`) | `App.jsx` | Array length grows in DevTools but UI doesn't re-render |
| 6 | Uncontrolled → controlled input | `AddTaskForm.jsx` | Hook state goes from `undefined` → string; console warning |
| 7 | Wrong initial state type (`null` vs `[]`) | `App.jsx` | Red error overlay; state panel shows `null` |

Each fix is also annotated inline in its source file with a
`FIX #N` comment, so `grep -rn "FIX #" src/` gives you the whole list.

## Getting started

```bash
npm install
npm run dev
```

Runs at [http://localhost:5173](http://localhost:5173).

## Setting up React Developer Tools

1. Install the extension:
   - Chrome: <https://chromewebstore.google.com/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi>
   - Firefox: <https://addons.mozilla.org/en-US/firefox/addon/react-devtools/>
2. Reload the app in your browser.
3. Open DevTools (⌥⌘I / F12) — you'll see two new tabs:
   - **⚛ Components** — inspect any component, its props, its hooks
     (state, refs, effects), and its render count.
   - **⚛ Profiler** — record a session, then see which components
     rendered, how long they took, and why.

## Verifying the fix

```bash
npm run build   # runs oxlint + vite build; passes cleanly
npm run dev     # try the app manually — no console warnings
```

Manual checklist:

- [x] No warnings in the browser console
- [x] `LiveCounter` counts smoothly upward
- [x] Deleting the *middle* task removes exactly that task
- [x] Adding a task re-renders the list immediately
- [x] Profiler shows `<LiveCounter>` renders once per second (not more)
