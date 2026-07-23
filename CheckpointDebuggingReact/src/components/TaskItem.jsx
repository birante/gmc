export default function TaskItem({ task, onToggle, onDelete }) {
  return (
    <li className={`task ${task.isDone ? "done" : ""}`}>
      <input
        type="checkbox"
        checked={task.isDone}
        onChange={() => onToggle(task.id)}
        aria-label={`Toggle "${task.description}"`}
      />
      <span className="description">{task.description}</span>
      <button
        type="button"
        className="delete"
        onClick={() => onDelete(task.id)}
        aria-label={`Delete "${task.description}"`}
      >
        Delete
      </button>
    </li>
  );
}
