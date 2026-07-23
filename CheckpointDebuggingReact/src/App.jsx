import { useState } from "react";
import UserProfile from "./components/UserProfile";
import LiveCounter from "./components/LiveCounter";
import AddTaskForm from "./components/AddTaskForm";
import FilterBar from "./components/FilterBar";
import TaskList from "./components/TaskList";
import "./App.css";

const initialUser = {
  id: 1,
  name: "Birante Sy",
  email: "birante.sy@pasteur.sn",
  avatar: "https://api.dicebear.com/9.x/initials/svg?seed=BS",
};

const initialTasks = [
  { id: 1, description: "Install React DevTools extension", isDone: true },
  { id: 2, description: "Read the Components + Profiler tabs docs", isDone: true },
  { id: 3, description: "Find and fix the bugs in this checkpoint", isDone: false },
];

export default function App() {
  const [user] = useState(initialUser);
  const [tasks, setTasks] = useState(initialTasks);
  const [filter, setFilter] = useState("all");

  const addTask = (description) => {
    // FIX #5 (state mutation):
    //   Buggy version was: `tasks.push({...}); setTasks(tasks);`
    //   That mutates the same array reference — React sees the same
    //   reference in setState and skips the re-render because
    //   Object.is(prev, next) is true. Spreading into a new array
    //   creates a fresh reference and triggers the update.
    setTasks((prev) => [
      ...prev,
      { id: Date.now(), description, isDone: false },
    ]);
  };

  const toggleTask = (id) => {
    setTasks((prev) =>
      prev.map((task) =>
        task.id === id ? { ...task, isDone: !task.isDone } : task
      )
    );
  };

  const deleteTask = (id) => {
    setTasks((prev) => prev.filter((task) => task.id !== id));
  };

  const visibleTasks = tasks.filter((task) => {
    if (filter === "done") return task.isDone;
    if (filter === "notDone") return !task.isDone;
    return true;
  });

  return (
    <div className="app">
      <header className="header">
        <h1>React DevTools Debugging Checkpoint</h1>
        <LiveCounter />
      </header>

      <UserProfile user={user} />

      <section className="tasks">
        <AddTaskForm onAdd={addTask} />
        <FilterBar filter={filter} onChange={setFilter} />
        <TaskList
          tasks={visibleTasks}
          onToggle={toggleTask}
          onDelete={deleteTask}
        />
      </section>
    </div>
  );
}
