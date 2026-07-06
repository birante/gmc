import React from "react";

// A single task row. The body is clickable to enter edit mode, the checkbox
// toggles the completed flag, and the delete button prompts for confirmation
// before firing onDelete.
function TaskItem({ task, onToggle, onEdit, onDelete }) {
  const handleDelete = () => {
    const ok = window.confirm(`Delete "${task.name}"? This cannot be undone.`);
    if (ok) onDelete(task.id);
  };

  return (
    <li className={`task ${task.completed ? "task--completed" : ""}`}>
      <input
        type="checkbox"
        className="task__checkbox"
        checked={task.completed}
        onChange={() => onToggle(task.id)}
        aria-label={`Mark "${task.name}" as ${
          task.completed ? "active" : "completed"
        }`}
      />

      <div
        className="task__body"
        onClick={() => onEdit(task)}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === "Enter") onEdit(task);
        }}
        title="Click to edit"
      >
        <p className="task__name">{task.name}</p>
        <p className="task__desc">{task.description}</p>
      </div>

      <div className="task__actions">
        <button
          type="button"
          className="task__icon-btn"
          onClick={() => onEdit(task)}
          aria-label="Edit task"
        >
          ✎ Edit
        </button>
        <button
          type="button"
          className="task__icon-btn task__icon-btn--danger"
          onClick={handleDelete}
          aria-label="Delete task"
        >
          🗑 Delete
        </button>
      </div>
    </li>
  );
}

export default TaskItem;
