import React, { useState, useEffect, useMemo } from "react";
import TaskForm from "./components/TaskForm";
import TaskList from "./components/TaskList";
import FilterBar from "./components/FilterBar";

const STORAGE_KEY = "todo.tasks.v1";

// Generate a stable id. Prefer crypto.randomUUID when available and fall back
// to a timestamp-based id in older browsers or non-secure contexts.
const newId = () =>
  typeof crypto !== "undefined" && crypto.randomUUID
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.floor(Math.random() * 1e6)}`;

// Lazy initializer for useState: reads once on first render and skips
// localStorage on every subsequent render.
const loadTasks = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
};

function App() {
  const [tasks, setTasks] = useState(loadTasks);
  const [filter, setFilter] = useState("all");
  const [editingTask, setEditingTask] = useState(null);

  // Persist tasks to localStorage whenever the list changes.
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
    } catch {
      // Storage full or blocked — silently ignore; app still works in-memory.
    }
  }, [tasks]);

  // ---- CRUD handlers ----
  const addTask = ({ name, description }) => {
    setTasks((prev) => [
      { id: newId(), name, description, completed: false, createdAt: Date.now() },
      ...prev,
    ]);
  };

  const updateTask = ({ name, description }) => {
    if (!editingTask) return;
    setTasks((prev) =>
      prev.map((t) =>
        t.id === editingTask.id ? { ...t, name, description } : t
      )
    );
    setEditingTask(null);
  };

  const toggleTask = (id) => {
    setTasks((prev) =>
      prev.map((t) => (t.id === id ? { ...t, completed: !t.completed } : t))
    );
  };

  const deleteTask = (id) => {
    setTasks((prev) => prev.filter((t) => t.id !== id));
    if (editingTask?.id === id) setEditingTask(null);
  };

  // ---- Derived state ----
  const counts = useMemo(
    () => ({
      all: tasks.length,
      active: tasks.filter((t) => !t.completed).length,
      completed: tasks.filter((t) => t.completed).length,
    }),
    [tasks]
  );

  const visibleTasks = useMemo(() => {
    if (filter === "active") return tasks.filter((t) => !t.completed);
    if (filter === "completed") return tasks.filter((t) => t.completed);
    return tasks;
  }, [tasks, filter]);

  return (
    <div className="app">
      <h1 className="app__title">My To-Do List</h1>

      <TaskForm
        initialTask={editingTask}
        onSubmit={editingTask ? updateTask : addTask}
        onCancel={() => setEditingTask(null)}
      />

      <FilterBar value={filter} onChange={setFilter} counts={counts} />

      <TaskList
        tasks={visibleTasks}
        onToggle={toggleTask}
        onEdit={setEditingTask}
        onDelete={deleteTask}
      />
    </div>
  );
}

export default App;
