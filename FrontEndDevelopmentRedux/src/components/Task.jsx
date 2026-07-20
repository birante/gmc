import { useState } from 'react'
import { useDispatch } from 'react-redux'
import { toggleTask, editTask, deleteTask } from '../redux/tasksSlice'

export default function Task({ task }) {
  const dispatch = useDispatch()
  const [isEditing, setIsEditing] = useState(false)
  const [draft, setDraft] = useState(task.description)

  const handleSave = () => {
    const trimmed = draft.trim()
    if (trimmed) {
      dispatch(editTask({ id: task.id, description: trimmed }))
    } else {
      setDraft(task.description)
    }
    setIsEditing(false)
  }

  const handleCancel = () => {
    setDraft(task.description)
    setIsEditing(false)
  }

  return (
    <li className={`task ${task.isDone ? 'done' : ''}`}>
      <input
        type="checkbox"
        checked={task.isDone}
        onChange={() => dispatch(toggleTask(task.id))}
      />

      {isEditing ? (
        <input
          className="edit-input"
          type="text"
          value={draft}
          autoFocus
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') handleSave()
            if (e.key === 'Escape') handleCancel()
          }}
        />
      ) : (
        <span className="description" onDoubleClick={() => setIsEditing(true)}>
          {task.description}
        </span>
      )}

      <div className="actions">
        {isEditing ? (
          <>
            <button onClick={handleSave}>Save</button>
            <button onClick={handleCancel}>Cancel</button>
          </>
        ) : (
          <>
            <button onClick={() => setIsEditing(true)}>Edit</button>
            <button onClick={() => dispatch(deleteTask(task.id))}>Delete</button>
          </>
        )}
      </div>
    </li>
  )
}
