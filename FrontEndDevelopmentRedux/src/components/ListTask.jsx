import { useSelector, useDispatch } from 'react-redux'
import {
  selectFilteredTasks,
  selectFilter,
  setFilter,
} from '../redux/tasksSlice'
import Task from './Task'

const FILTERS = [
  { key: 'all', label: 'All' },
  { key: 'done', label: 'Done' },
  { key: 'notDone', label: 'Not Done' },
]

export default function ListTask() {
  const tasks = useSelector(selectFilteredTasks)
  const filter = useSelector(selectFilter)
  const dispatch = useDispatch()

  return (
    <section className="list-task">
      <div className="filters">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            className={filter === f.key ? 'active' : ''}
            onClick={() => dispatch(setFilter(f.key))}
          >
            {f.label}
          </button>
        ))}
      </div>

      {tasks.length === 0 ? (
        <p className="empty">No tasks to show.</p>
      ) : (
        <ul className="tasks">
          {tasks.map((task) => (
            <Task key={task.id} task={task} />
          ))}
        </ul>
      )}
    </section>
  )
}
