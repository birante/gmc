import TaskItem from "./TaskItem";

// FIX #1 (missing key prop) + FIX #7 (defensive rendering):
//
//   Buggy #1: <TaskItem task={t} /> without a `key` prop caused
//   React to warn in the console: "Each child in a list should have
//   a unique 'key' prop." In the Components tab, editing a task in
//   the middle of the list caused the WRONG item to update because
//   React couldn't correctly diff. Fix: pass `key={task.id}`.
//
//   Buggy #7: an earlier version used `tasks.map(...)` where `tasks`
//   was initialized as `null`, throwing:
//     "Cannot read properties of null (reading 'map')".
//   The stack trace pointed here. Fix: initialize state to `[]` in
//   App.jsx AND guard here with `tasks?.length` for extra safety.

export default function TaskList({ tasks, onToggle, onDelete }) {
  if (!tasks?.length) {
    return <p className="empty">No tasks to show.</p>;
  }

  return (
    <ul className="task-list">
      {tasks.map((task) => (
        <TaskItem
          key={task.id}
          task={task}
          onToggle={onToggle}
          onDelete={onDelete}
        />
      ))}
    </ul>
  );
}
