import { useCallback, useEffect, useState } from 'react';
import { tasksApi } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import StatsPanel from '../components/StatsPanel.jsx';
import Toolbar from '../components/Toolbar.jsx';
import TaskCard from '../components/TaskCard.jsx';
import TaskForm from '../components/TaskForm.jsx';
import Modal from '../components/Modal.jsx';

function useDebounced(value, delay = 300) {
  const [v, setV] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setV(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return v;
}

export default function Dashboard() {
  const { user } = useAuth();
  const [tasks, setTasks] = useState([]);
  const [stats, setStats] = useState(null);
  const [status, setStatus] = useState('');
  const [search, setSearch] = useState('');
  const [sort, setSort] = useState('-createdAt');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(null); // null = fermé, {} = création, task = édition
  const [toast, setToast] = useState('');
  const debouncedSearch = useDebounced(search);

  const refresh = useCallback(async () => {
    try {
      const [list, st] = await Promise.all([tasksApi.list({ status, search: debouncedSearch, sort }), tasksApi.stats()]);
      setTasks(list.tasks);
      setStats(st);
      setError('');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [status, debouncedSearch, sort]);

  useEffect(() => { refresh(); }, [refresh]);

  useEffect(() => {
    if (!toast) return undefined;
    const id = setTimeout(() => setToast(''), 2500);
    return () => clearTimeout(id);
  }, [toast]);

  const handleStatusChange = async (task, next) => {
    try {
      await tasksApi.setStatus(task.id, next);
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (task) => {
    if (!window.confirm(`Supprimer la tâche « ${task.title} » ?`)) return;
    try {
      await tasksApi.remove(task.id);
      setToast('Tâche supprimée');
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleSubmit = async (payload) => {
    if (editing?.id) {
      await tasksApi.update(editing.id, payload);
      setToast('Tâche modifiée');
    } else {
      await tasksApi.create(payload);
      setToast('Tâche créée');
    }
    setEditing(null);
    await refresh();
  };

  const closeModal = useCallback(() => setEditing(null), []);
  const firstName = user?.name?.split(' ')[0] || '';

  return (
    <div className="dashboard">
      <div className="dash-head">
        <div>
          <h1>Bonjour {firstName} 👋</h1>
          <p className="muted">Voici où en sont vos tâches.</p>
        </div>
        <button type="button" className="btn btn-primary" onClick={() => setEditing({})}>+ Nouvelle tâche</button>
      </div>

      <StatsPanel stats={stats} />

      <Toolbar status={status} onStatus={setStatus} search={search} onSearch={setSearch} sort={sort} onSort={setSort} counts={stats} />

      {error && <div className="alert" role="alert">{error}</div>}

      {loading ? (
        <p className="muted center" role="status">Chargement des tâches…</p>
      ) : tasks.length === 0 ? (
        <div className="empty card">
          <p className="empty-title">{search || status ? 'Aucune tâche ne correspond à vos critères.' : 'Aucune tâche pour le moment.'}</p>
          {!search && !status && <button type="button" className="btn btn-primary" onClick={() => setEditing({})}>Créer ma première tâche</button>}
        </div>
      ) : (
        <div className="task-grid">
          {tasks.map((t) => (
            <TaskCard key={t.id} task={t} onStatusChange={handleStatusChange} onEdit={setEditing} onDelete={handleDelete} />
          ))}
        </div>
      )}

      {editing && (
        <Modal title={editing.id ? 'Modifier la tâche' : 'Nouvelle tâche'} onClose={closeModal}>
          <TaskForm initial={editing.id ? editing : null} onSubmit={handleSubmit} onCancel={closeModal} />
        </Modal>
      )}

      {toast && <div className="toast" role="status">{toast}</div>}
    </div>
  );
}
