import { useCallback, useState } from 'react';
import TaskItem from './TaskItem.jsx';
import { PRIORITIES, buildTasks, makeTask, nextPriority } from './tasks.js';

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [editingId, setEditingId] = useState(null);
  const [name, setName] = useState('');
  const [priority, setPriority] = useState('medium');

  const addTask = (e) => {
    e.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    setTasks((ts) => [...ts, makeTask(trimmed, priority)]);
    setName('');
  };

  // Stable callbacks (functional updates) so memoized rows are not invalidated.
  const onEdit = useCallback((id) => setEditingId(id), []);
  const onCancel = useCallback(() => setEditingId(null), []);
  const onRemove = useCallback((id) => setTasks((ts) => ts.filter((t) => t.id !== id)), []);
  const onSave = useCallback((id, newName, newPriority) => {
    const trimmed = newName.trim();
    setTasks((ts) => ts.map((t) => (t.id === id ? { ...t, name: trimmed || t.name, priority: newPriority } : t)));
    setEditingId(null);
  }, []);

  // Benchmark operations
  const run = (n) => { setEditingId(null); setTasks(buildTasks(n)); };
  // Immutable update: only the 50 changed rows get new object identities.
  const update50 = () =>
    setTasks((ts) => ts.map((t, i) => (i < 50 ? { ...t, name: t.name + ' !!!', priority: nextPriority(t.priority) } : t)));
  const delete50 = () => setTasks((ts) => ts.slice(50));
  const clear = () => { setEditingId(null); setTasks([]); };

  return (
    <main id="app" className="container" data-framework="react">
      <h1>To-Do List <small>(React)</small></h1>

      <form id="add-form" data-testid="add-form" onSubmit={addTask}>
        <input
          id="task-name"
          data-testid="task-name"
          placeholder="Task name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <select id="task-priority" data-testid="task-priority" value={priority} onChange={(e) => setPriority(e.target.value)}>
          {PRIORITIES.map((p) => (
            <option key={p} value={p}>{p}</option>
          ))}
        </select>
        <button id="add-task" data-testid="add-task" type="submit">Add</button>
      </form>

      <div id="bench" className="bench" data-testid="bench">
        <button id="run-100" data-testid="run-100" type="button" onClick={() => run(100)}>Render 100</button>
        <button id="run-500" data-testid="run-500" type="button" onClick={() => run(500)}>Render 500</button>
        <button id="run-1000" data-testid="run-1000" type="button" onClick={() => run(1000)}>Render 1000</button>
        <button id="update-50" data-testid="update-50" type="button" onClick={update50}>Update 50</button>
        <button id="delete-50" data-testid="delete-50" type="button" onClick={delete50}>Delete 50</button>
        <button id="clear" data-testid="clear" type="button" onClick={clear}>Clear</button>
      </div>

      <p id="task-count" data-testid="task-count">{tasks.length} tasks</p>

      <ul id="task-list" data-testid="task-list">
        {tasks.map((task) => (
          <TaskItem
            key={task.id}
            task={task}
            editing={task.id === editingId}
            onEdit={onEdit}
            onSave={onSave}
            onCancel={onCancel}
            onRemove={onRemove}
          />
        ))}
      </ul>
      {tasks.length === 0 && <p className="empty" data-testid="empty">No tasks yet.</p>}
    </main>
  );
}
