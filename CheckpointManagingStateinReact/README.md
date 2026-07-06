# Managing State in React — To-Do List

A React To-Do List that demonstrates state management with hooks:

- Add tasks via a validated form (name + description are required)
- Mark tasks complete / active (visually distinguished)
- Click a task to edit it — the form is pre-filled with its current values
- Delete a task (with a confirmation prompt)
- Filter by status (all / active / completed)
- Tasks are persisted to `localStorage` and reloaded on next visit

## Project structure

```
src/
├── App.js               # top-level state, glue between components, localStorage sync
├── index.js / index.css
└── components/
    ├── TaskForm.js      # add/edit form with validation
    ├── TaskList.js      # renders the (filtered) list of tasks
    ├── TaskItem.js      # a single row with complete/edit/delete controls
    └── FilterBar.js     # tabs to switch between all / active / completed
```

## Getting started

```bash
npm install
npm start
```

Runs at [http://localhost:3000](http://localhost:3000).

## Notes

- Storage key is `todo.tasks.v1`. Delete it from the browser DevTools
  (Application → Local Storage) to reset the app.
- Task IDs are generated with `crypto.randomUUID()` (falls back to
  `Date.now()` in older browsers).
