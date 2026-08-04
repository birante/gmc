// In-memory task store. Every operation is owner-scoped so the
// controller cannot accidentally return or delete someone else's task.

const crypto = require("crypto");

const tasksById = new Map();          // id -> task
const tasksByOwner = new Map();       // ownerId -> Set<taskId>

function newId() { return crypto.randomUUID(); }

async function create({ ownerId, title, description = "" }) {
  const task = {
    id: newId(),
    ownerId,
    title,
    description,
    completed: false,
    createdAt: new Date(),
  };
  tasksById.set(task.id, task);
  if (!tasksByOwner.has(ownerId)) tasksByOwner.set(ownerId, new Set());
  tasksByOwner.get(ownerId).add(task.id);
  return task;
}

async function findByOwner(ownerId) {
  const ids = tasksByOwner.get(ownerId);
  if (!ids) return [];
  return [...ids].map(id => tasksById.get(id)).filter(Boolean);
}

// Owner-scoped read — used by the DELETE handler to validate ownership
// before actually deleting.
async function findByIdForOwner(id, ownerId) {
  const task = tasksById.get(id);
  if (!task || task.ownerId !== ownerId) return null;
  return task;
}

async function deleteByIdForOwner(id, ownerId) {
  const task = tasksById.get(id);
  if (!task || task.ownerId !== ownerId) return false;
  tasksById.delete(id);
  tasksByOwner.get(ownerId)?.delete(id);
  return true;
}

function _reset() {
  tasksById.clear();
  tasksByOwner.clear();
}

module.exports = { create, findByOwner, findByIdForOwner, deleteByIdForOwner, _reset };
