const AppError = require("../utils/AppError");
const Task = require("../models/Task");

const MAX_TITLE = 200;
const MAX_DESC  = 2000;

async function create(req, res) {
  const { title, description = "" } = req.body || {};
  if (typeof title !== "string" || title.trim() === "") {
    throw new AppError("Title is required", 400);
  }
  if (title.length > MAX_TITLE) throw new AppError("Title too long", 400);
  if (typeof description !== "string" || description.length > MAX_DESC) {
    throw new AppError("Description invalid or too long", 400);
  }

  const task = await Task.create({
    ownerId: req.user.id,
    title: title.trim(),
    description: description.trim(),
  });
  res.status(201).json({ task });
}

async function list(req, res) {
  const tasks = await Task.findByOwner(req.user.id);
  res.json({ tasks });
}

async function remove(req, res) {
  const { id } = req.params;
  const ok = await Task.deleteByIdForOwner(id, req.user.id);
  if (!ok) throw new AppError("Task not found", 404);
  res.status(204).end();
}

module.exports = { create, list, remove };
