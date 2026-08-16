// Single-page CRUD app on top of /api/users.
// Uses fetch() — no axios dep needed for a call this small.

import { useEffect, useState } from "react";

const emptyForm = { name: "", email: "", role: "member" };

export default function App() {
  const [users, setUsers]     = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState(null);
  const [form, setForm]       = useState(emptyForm);
  const [editingId, setEditingId] = useState(null);

  async function refresh() {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/users");
      if (!res.ok) throw new Error(`GET failed (${res.status})`);
      const body = await res.json();
      setUsers(body.users);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { refresh(); }, []);

  async function submit(event) {
    event.preventDefault();
    setError(null);
    try {
      const method = editingId ? "PUT" : "POST";
      const url    = editingId ? `/api/users/${editingId}` : "/api/users";
      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(body.error ?? `${method} failed (${res.status})`);
      setForm(emptyForm);
      setEditingId(null);
      refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  async function remove(id) {
    if (!confirm("Delete this user?")) return;
    setError(null);
    try {
      const res = await fetch(`/api/users/${id}`, { method: "DELETE" });
      if (!res.ok && res.status !== 204) throw new Error(`DELETE failed (${res.status})`);
      refresh();
    } catch (err) {
      setError(err.message);
    }
  }

  function startEdit(user) {
    setForm({ name: user.name, email: user.email, role: user.role });
    setEditingId(user._id);
  }

  function cancelEdit() {
    setForm(emptyForm);
    setEditingId(null);
  }

  return (
    <main className="app">
      <header className="app__header">
        <h1>Users</h1>
        <p className="muted">MERN stack (Mongo + Express + React + Node), served by the same Node process, deployable on Azure App Service.</p>
      </header>

      <form className="card form" onSubmit={submit}>
        <h2>{editingId ? "Edit user" : "Add a user"}</h2>
        <div className="row">
          <label>
            Name
            <input
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              required
            />
          </label>
          <label>
            Email
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              required
            />
          </label>
          <label>
            Role
            <select
              value={form.role}
              onChange={(e) => setForm({ ...form, role: e.target.value })}
            >
              <option value="admin">admin</option>
              <option value="member">member</option>
              <option value="viewer">viewer</option>
            </select>
          </label>
        </div>
        <div className="actions">
          <button type="submit" className="btn primary">
            {editingId ? "Save changes" : "Add user"}
          </button>
          {editingId && (
            <button type="button" className="btn" onClick={cancelEdit}>Cancel</button>
          )}
        </div>
      </form>

      {error && <div className="alert error">{error}</div>}

      <section className="card">
        <h2>{loading ? "Loading…" : `Users (${users.length})`}</h2>
        {!loading && users.length === 0 && (
          <p className="muted">No users yet — add one above.</p>
        )}
        <ul className="user-list">
          {users.map((u) => (
            <li key={u._id} className="user">
              <div className="user__info">
                <strong>{u.name}</strong>
                <span className="muted">{u.email}</span>
                <span className={`badge badge--${u.role}`}>{u.role}</span>
              </div>
              <div className="user__actions">
                <button className="btn" onClick={() => startEdit(u)}>Edit</button>
                <button className="btn danger" onClick={() => remove(u._id)}>Delete</button>
              </div>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
