# Redux Checkpoint — To-Do List

A React To-Do List that demonstrates global state management with Redux Toolkit:

- Add a new task via a form (empty descriptions are rejected)
- Mark tasks done / not done with a checkbox (visually struck-through when done)
- Edit a task inline (double-click the description or press the **Edit** button;
  press Enter to save, Escape to cancel)
- Delete a task
- Filter the list by status (all / done / not done)

Each task has three attributes: `id`, `description`, `isDone`.

## Project structure

```text
src/
├── App.jsx                    # top-level layout (AddTask + ListTask)
├── main.jsx                   # wraps <App /> in <Provider store={store}>
├── redux/
│   ├── store.js               # configureStore
│   └── tasksSlice.js          # actions, reducers, selectors
└── components/
    ├── AddTask.jsx            # form to create a new task
    ├── ListTask.jsx           # filter bar + list of tasks
    └── Task.jsx               # a single task row (toggle / edit / delete)
```

## Getting started

```bash
npm install
npm run dev
```

Runs at [http://localhost:5173](http://localhost:5173).

## Notes

- Built with **Vite + React 19** and **Redux Toolkit** (`@reduxjs/toolkit`,
  `react-redux`).
- Task IDs are generated with `nanoid` (re-exported from Redux Toolkit).
- State lives entirely in the Redux store — components read it with
  `useSelector` and dispatch actions with `useDispatch`.
