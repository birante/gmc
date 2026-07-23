# Debugging Report — 7 Bugs Found and Fixed with React DevTools

This document walks through every bug that was in the original version of
this app, how **React Developer Tools** helped diagnose it, and the exact
fix that was applied. Each entry follows the same structure:

- **Symptom** — what the user (or console) saw
- **How DevTools helped** — the specific tab / panel that pointed at
  the root cause
- **Root cause** — the underlying mistake
- **Fix** — the code change (before → after)

The final code in this repo is the **fixed** version. Each fix is also
annotated with a `FIX #N` comment in the corresponding component file so
you can jump straight to it.

---

## Bug #1 — Missing `key` prop on list items

**File:** `src/components/TaskList.jsx`

**Symptom.** Deleting the *middle* task made the *last* task disappear
instead. Editing the first task also flashed the wrong item briefly.
The browser console showed:

> Warning: Each child in a list should have a unique "key" prop.

**How DevTools helped.** In the **Components** tab, expanding
`<TaskList>` showed three `<TaskItem>` children with **no `key`**
displayed on any of them. React was matching them by array position
instead of identity, so a deletion shifted every task up by one slot.

**Root cause.** `tasks.map(t => <TaskItem task={t} />)` — no `key`.

**Fix.**

```diff
- {tasks.map((task) => (
-   <TaskItem task={task} onToggle={onToggle} onDelete={onDelete} />
- ))}
+ {tasks.map((task) => (
+   <TaskItem
+     key={task.id}
+     task={task}
+     onToggle={onToggle}
+     onDelete={onDelete}
+   />
+ ))}
```

---

## Bug #2 — Wrong prop name (`userInfo` vs `user`)

**File:** `src/components/UserProfile.jsx`

**Symptom.** The profile card was blank. No name, no email, and a
broken avatar image icon. No console error — just a silent failure.

**How DevTools helped.** In the **Components** tab, I clicked
`<UserProfile>` and looked at the right-hand panel:

```
props:
  user: { id: 1, name: "Birante Sy", email: "...", avatar: "..." }
```

The prop was clearly named `user`. But the component code was
destructuring `{ userInfo }` — which was `undefined`. That's why every
`userInfo.something` rendered as blank.

**Root cause.** Prop name mismatch between parent (`user`) and child
(`userInfo`).

**Fix.**

```diff
- export default function UserProfile({ userInfo }) {
-   return <img src={userInfo.avatar} alt={userInfo.name} />;
- }
+ export default function UserProfile({ user }) {
+   return <img src={user.avatar} alt={user.name} />;
+ }
```

**Lesson.** DevTools shows the *actual* props passed by the parent —
if what you destructure inside the component doesn't match, you'll
see `undefined` everywhere.

---

## Bug #3 — Stale closure in `setInterval`

**File:** `src/components/LiveCounter.jsx`

**Symptom.** The seconds counter jumped from `0s → 1s` and then froze.
It never went to 2, 3, 4…

**How DevTools helped.** In the **Components** tab, expanding
`<LiveCounter>` and watching the `State` panel, I could see:

```
State:
  seconds: 1
```

The state was updating exactly once, then never again. That's the
classic signature of a stale closure inside `setInterval`.

**Root cause.**

```js
useEffect(() => {
  setInterval(() => setSeconds(seconds + 1), 1000);
}, []);
```

The empty dependency array runs the effect once. `seconds` inside the
callback is captured at that first render (value = 0). Every tick
calls `setSeconds(0 + 1)` → the state is always set to 1.

**Fix.** Use the updater form so React passes in the current value:

```diff
- setInterval(() => setSeconds(seconds + 1), 1000);
+ setInterval(() => setSeconds((prev) => prev + 1), 1000);
```

---

## Bug #4 — Missing `useEffect` cleanup (interval leak)

**File:** `src/components/LiveCounter.jsx`

**Symptom.** The app felt fine for the first few seconds, then started
to lag. Hot-reloading during dev made things get worse fast.

**How DevTools helped.** In the **⚛ Profiler** tab I clicked
*Record*, waited five seconds, then stopped. The flame graph showed
`<LiveCounter>` re-rendering multiple times per second — and the
render count kept climbing as I waited. Each StrictMode re-mount was
stacking a new interval without ever clearing the old one.

**Root cause.** `useEffect` returned nothing — no cleanup.

**Fix.**

```diff
  useEffect(() => {
-   setInterval(() => setSeconds((prev) => prev + 1), 1000);
+   const id = setInterval(() => setSeconds((prev) => prev + 1), 1000);
+   return () => clearInterval(id);
  }, []);
```

---

## Bug #5 — Direct state mutation

**File:** `src/App.jsx` (`addTask`)

**Symptom.** Typing a new task and clicking **Add** did nothing —
the list looked identical. But refreshing the page also lost the entry,
so it wasn't a persistence bug.

**How DevTools helped.** In the **Components** tab, I selected `<App>`
and watched the `hooks[0].value` (the `tasks` array). Adding a task
*did* mutate the array — I could see its `.length` grow in DevTools —
but the UI never re-rendered because React compares the new state to
the old with `Object.is()`, and mutating the array in place gives back
the same reference.

**Root cause.**

```js
const addTask = (description) => {
  tasks.push({ id: Date.now(), description, isDone: false });
  setTasks(tasks); // same reference → React skips re-render
};
```

**Fix.** Create a *new* array.

```diff
- tasks.push({ id: Date.now(), description, isDone: false });
- setTasks(tasks);
+ setTasks((prev) => [
+   ...prev,
+   { id: Date.now(), description, isDone: false },
+ ]);
```

---

## Bug #6 — Uncontrolled → controlled input warning

**File:** `src/components/AddTaskForm.jsx`

**Symptom.** The first character typed into the "Add task" input
worked fine, but the console lit up with:

> Warning: A component is changing an uncontrolled input to be
> controlled. This is likely caused by the value changing from
> undefined to a defined value…

**How DevTools helped.** In the **Components** tab, selecting
`<AddTaskForm>` and looking at the hooks panel showed
`State: undefined` on the very first render, then `State: "h"` on the
next. That transition (undefined → string) is exactly what the warning
is about.

**Root cause.** `useState()` was called without an initializer, so the
initial value was `undefined`.

**Fix.**

```diff
- const [description, setDescription] = useState();
+ const [description, setDescription] = useState("");
```

---

## Bug #7 — Wrong initial state type (`null` vs `[]`)

**File:** `src/App.jsx`

**Symptom.** The whole app crashed on load with:

> TypeError: Cannot read properties of null (reading 'map')

The red error overlay pointed at `TaskList` → `tasks.map(...)`.

**How DevTools helped.** In the **Components** tab, selecting `<App>`
before the crash (in an earlier moment of debugging) showed
`hooks[0].value: null`. Since arrays are supposed to be arrays,
initializing with `null` was clearly wrong.

**Root cause.**

```js
const [tasks, setTasks] = useState(null);
```

**Fix.** Initialize with an array. Also added a guard in `TaskList`
so a future `null` (from a bad API response, for instance) won't crash
the page:

```diff
- const [tasks, setTasks] = useState(null);
+ const [tasks, setTasks] = useState(initialTasks);

// TaskList.jsx
+ if (!tasks?.length) return <p className="empty">No tasks to show.</p>;
```

---

## Verification checklist

After all fixes:

- [x] No React warnings in the console when adding/toggling/deleting tasks
- [x] `LiveCounter` counts up smoothly (1s → 2s → 3s…)
- [x] `<UserProfile>` shows the correct name, email, and avatar
- [x] Deleting the middle task removes exactly that task
- [x] Adding a task re-renders the list immediately
- [x] Profiler shows `<LiveCounter>` renders exactly once per second
- [x] `npm run build` succeeds

## Tooling used

- **React Developer Tools** (browser extension) — Components + Profiler tabs
- Chrome DevTools console — for warnings and error stack traces
- Vite dev server — for hot-reload / StrictMode double-invocation to
  surface effect-cleanup bugs faster
