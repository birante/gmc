import React, { useState, useEffect } from "react";

// Add-or-edit form. When `initialTask` is provided the form runs in "edit"
// mode: it is pre-filled and calling onSubmit patches the existing task.
// Otherwise it is in "add" mode and the caller inserts a new task.
function TaskForm({ initialTask, onSubmit, onCancel }) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [errors, setErrors] = useState({});

  const isEditing = Boolean(initialTask);

  // Reset the fields whenever the caller swaps which task we're editing.
  useEffect(() => {
    setName(initialTask?.name ?? "");
    setDescription(initialTask?.description ?? "");
    setErrors({});
  }, [initialTask]);

  const validate = () => {
    const next = {};
    if (!name.trim()) next.name = "Task name is required.";
    if (!description.trim()) next.description = "Description is required.";
    return next;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const nextErrors = validate();
    if (Object.keys(nextErrors).length > 0) {
      setErrors(nextErrors);
      return;
    }
    onSubmit({ name: name.trim(), description: description.trim() });
    if (!isEditing) {
      setName("");
      setDescription("");
    }
    setErrors({});
  };

  return (
    <form className="form card" onSubmit={handleSubmit} noValidate>
      <h2>{isEditing ? "Edit task" : "Add a new task"}</h2>

      <div className="form__field">
        <label htmlFor="task-name">Name</label>
        <input
          id="task-name"
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          className={errors.name ? "error" : ""}
          placeholder="e.g. Buy groceries"
        />
        {errors.name && <span className="form__error">{errors.name}</span>}
      </div>

      <div className="form__field">
        <label htmlFor="task-description">Description</label>
        <textarea
          id="task-description"
          rows={3}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          className={errors.description ? "error" : ""}
          placeholder="Details about the task"
        />
        {errors.description && (
          <span className="form__error">{errors.description}</span>
        )}
      </div>

      <div className="form__actions">
        {isEditing && (
          <button type="button" className="btn btn--ghost" onClick={onCancel}>
            Cancel
          </button>
        )}
        <button type="submit" className="btn btn--primary">
          {isEditing ? "Save changes" : "Add task"}
        </button>
      </div>
    </form>
  );
}

export default TaskForm;
