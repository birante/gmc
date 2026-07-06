import React from "react";
import TaskItem from "./TaskItem";

// Renders the (already filtered) list of tasks. Falls back to a friendly empty
// state if there is nothing to show.
function TaskList({ tasks, onToggle, onEdit, onDelete }) {
  if (tasks.length === 0) {
    return (
      <p className="task-list__empty">
        Nothing here yet — add your first task above.
      </p>
    );
  }

  return (
    <ul className="task-list">
      {tasks.map((task) => (
        <TaskItem
          key={task.id}
          task={task}
          onToggle={onToggle}
          onEdit={onEdit}
          onDelete={onDelete}
        />
      ))}
    </ul>
  );
}

export default TaskList;
