// In-memory store. A plain array of todos indexed by id.
// Kept behind a small API so the HTTP layer never touches the raw array.

import { randomUUID } from "node:crypto";

const todos = [];

export function listTodos() {
  return [...todos];
}

export function findTodo(id) {
  return todos.find(t => t.id === id) ?? null;
}

export function createTodo({ title, completed = false }) {
  const todo = { id: randomUUID(), title, completed: Boolean(completed) };
  todos.push(todo);
  return todo;
}

export function updateTodo(id, patch) {
  const todo = findTodo(id);
  if (!todo) return null;
  if (patch.title !== undefined)     todo.title = patch.title;
  if (patch.completed !== undefined) todo.completed = Boolean(patch.completed);
  return todo;
}

export function deleteTodo(id) {
  const idx = todos.findIndex(t => t.id === id);
  if (idx === -1) return false;
  todos.splice(idx, 1);
  return true;
}

// test-only: wipe state between test cases
export function _reset() {
  todos.length = 0;
}
