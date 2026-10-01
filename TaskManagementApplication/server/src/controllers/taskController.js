import mongoose from 'mongoose';
import { Task, STATUSES } from '../models/Task.js';
import { HttpError } from '../utils/HttpError.js';
import { escapeRegex } from '../utils/escapeRegex.js';

const SORTS = {
  deadline: { deadline: 1, createdAt: -1 },
  '-deadline': { deadline: -1, createdAt: -1 },
  priority: { priorityRank: 1, createdAt: -1 },
  '-priority': { priorityRank: -1, createdAt: -1 },
  createdAt: { createdAt: 1 },
  '-createdAt': { createdAt: -1 },
};
export const SORT_KEYS = Object.keys(SORTS);

const EDITABLE = ['title', 'description', 'deadline', 'priority', 'status'];

async function findOwnedTask(req) {
  const { id } = req.params;
  if (!mongoose.isValidObjectId(id)) throw new HttpError(404, 'Tâche introuvable');
  // Le filtre sur owner garantit l'isolation : la tâche d'un autre utilisateur est « introuvable »
  const task = await Task.findOne({ _id: id, owner: req.user._id });
  if (!task) throw new HttpError(404, 'Tâche introuvable');
  return task;
}

export async function listTasks(req, res, next) {
  try {
    const { status, search, sort = '-createdAt' } = req.query;
    const filter = { owner: req.user._id };
    if (status) filter.status = status;
    if (search && search.trim()) {
      const rx = new RegExp(escapeRegex(search.trim()), 'i');
      filter.$or = [{ title: rx }, { description: rx }];
    }
    const query = Task.find(filter).sort(SORTS[sort] || SORTS['-createdAt']);
    // Les tâches sans échéance passent en dernier quel que soit le sens du tri
    let tasks = await query;
    if (sort === 'deadline' || sort === '-deadline') {
      tasks = [...tasks.filter((t) => t.deadline), ...tasks.filter((t) => !t.deadline)];
    }
    res.json({ tasks, count: tasks.length });
  } catch (err) {
    next(err);
  }
}

export async function getStats(req, res, next) {
  try {
    const owner = req.user._id;
    const [byStatusAgg, overdue] = await Promise.all([
      Task.aggregate([{ $match: { owner } }, { $group: { _id: '$status', count: { $sum: 1 } } }]),
      Task.countDocuments({ owner, status: { $ne: 'done' }, deadline: { $ne: null, $lt: new Date() } }),
    ]);
    const byStatus = Object.fromEntries(STATUSES.map((s) => [s, 0]));
    byStatusAgg.forEach((row) => {
      byStatus[row._id] = row.count;
    });
    const total = Object.values(byStatus).reduce((a, b) => a + b, 0);
    const completionRate = total ? Math.round((byStatus.done / total) * 100) : 0;
    res.json({ total, byStatus, overdue, completionRate });
  } catch (err) {
    next(err);
  }
}

export async function createTask(req, res, next) {
  try {
    const data = { owner: req.user._id };
    EDITABLE.forEach((k) => {
      if (req.body[k] !== undefined) data[k] = req.body[k];
    });
    const task = new Task(data);
    await task.save();
    res.status(201).json({ task });
  } catch (err) {
    next(err);
  }
}

export async function getTask(req, res, next) {
  try {
    res.json({ task: await findOwnedTask(req) });
  } catch (err) {
    next(err);
  }
}

export async function updateTask(req, res, next) {
  try {
    const task = await findOwnedTask(req);
    EDITABLE.forEach((k) => {
      if (req.body[k] !== undefined) task[k] = req.body[k];
    });
    await task.save();
    res.json({ task });
  } catch (err) {
    next(err);
  }
}

export async function updateStatus(req, res, next) {
  try {
    const task = await findOwnedTask(req);
    task.status = req.body.status;
    await task.save();
    res.json({ task });
  } catch (err) {
    next(err);
  }
}

export async function deleteTask(req, res, next) {
  try {
    const task = await findOwnedTask(req);
    await task.deleteOne();
    res.status(204).end();
  } catch (err) {
    next(err);
  }
}
