import { memo, useState } from 'react';
import { PRIORITIES } from './tasks.js';

// memo(): a row only re-renders when its own `task` object (or editing flag) changes.
// Callbacks are stable (useCallback in App), so untouched rows are skipped entirely.
function TaskItem({ task, editing, onEdit, onSave, onCancel, onRemove }) {
  const [draftName, setDraftName] = useState(task.name);
  const [draftPriority, setDraftPriority] = useState(task.priority);

  if (editing) {
    return (
      <li className="task editing" data-testid="task" data-id={task.id}>
        <input
          className="edit-name"
          data-testid="edit-name"
          value={draftName}
          onChange={(e) => setDraftName(e.target.value)}
        />
        <select
          className="edit-priority"
          data-testid="edit-priority"
          value={draftPriority}
          onChange={(e) => setDraftPriority(e.target.value)}
        >
          {PRIORITIES.map((p) => (
            <option key={p} value={p}>{p}</option>
          ))}
        </select>
        <button type="button" className="save" data-testid="save" onClick={() => onSave(task.id, draftName, draftPriority)}>Save</button>
        <button type="button" className="cancel" data-testid="cancel" onClick={onCancel}>Cancel</button>
      </li>
    );
  }

  return (
    <li className="task" data-testid="task" data-id={task.id}>
      <span className="task-name">{task.name}</span>
      <span className={`badge priority-${task.priority}`} data-testid="priority">{task.priority}</span>
      <button
        type="button"
        className="edit"
        data-testid="edit"
        onClick={() => {
          setDraftName(task.name);
          setDraftPriority(task.priority);
          onEdit(task.id);
        }}
      >Edit</button>
      <button type="button" className="remove" data-testid="remove" onClick={() => onRemove(task.id)}>Remove</button>
    </li>
  );
}

export default memo(TaskItem);
