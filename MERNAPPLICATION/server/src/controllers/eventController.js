import mongoose from 'mongoose';
import { Event } from '../models/Event.js';
import { HttpError } from '../utils/httpError.js';

const PAGE_SIZE = 9;
const EDITABLE_FIELDS = ['title', 'description', 'date', 'location', 'category', 'capacity', 'imageUrl'];
const ORGANIZER_FIELDS = 'name bio';

const idOf = (v) => (v && v._id ? v._id : v)?.toString();

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Sérialise un événement pour l'API (sans exposer la liste brute des inscrits). */
export const serializeEvent = (event, user, { withParticipants = false } = {}) => {
  const json = event.toJSON();
  const userId = user?._id?.toString();
  const attendees = event.attendees || [];
  json.isRegistered = Boolean(userId && attendees.some((a) => idOf(a) === userId));
  json.isOrganizer = Boolean(userId && idOf(event.organizer) === userId);
  if (withParticipants && json.isOrganizer) {
    json.participants = attendees.map((a) => ({ id: idOf(a), name: a.name, email: a.email }));
  }
  delete json.attendees;
  return json;
};

const assertValidId = (id) => {
  if (!mongoose.isValidObjectId(id)) throw new HttpError(404, 'Événement introuvable');
};

const findEventOr404 = async (id) => {
  assertValidId(id);
  const event = await Event.findById(id);
  if (!event) throw new HttpError(404, 'Événement introuvable');
  return event;
};

const assertOrganizer = (event, user) => {
  if (event.organizer.toString() !== user._id.toString()) {
    throw new HttpError(403, "Seul l'organisateur peut modifier ou supprimer cet événement");
  }
};

export const buildFilter = ({ search, category, when }) => {
  const filter = {};
  if (search && search.trim()) {
    const rx = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [{ title: rx }, { description: rx }, { location: rx }];
  }
  if (category) filter.category = category;
  const now = new Date();
  if (when === 'upcoming') filter.date = { $gte: now };
  if (when === 'past') filter.date = { $lt: now };
  return filter;
};

export const listEvents = async (req, res) => {
  const { when } = req.query;
  const page = Math.max(1, parseInt(req.query.page, 10) || 1);
  const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || PAGE_SIZE));
  const filter = buildFilter(req.query);
  const sort = when === 'past' ? { date: -1 } : { date: 1 };

  const [total, events] = await Promise.all([
    Event.countDocuments(filter),
    Event.find(filter)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('organizer', ORGANIZER_FIELDS),
  ]);

  res.json({
    events: events.map((e) => serializeEvent(e, req.user)),
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit)),
  });
};

export const getEvent = async (req, res) => {
  assertValidId(req.params.id);
  const event = await Event.findById(req.params.id).populate('organizer', ORGANIZER_FIELDS);
  if (!event) throw new HttpError(404, 'Événement introuvable');
  const isOrganizer = req.user && idOf(event.organizer) === req.user._id.toString();
  if (isOrganizer) await event.populate('attendees', 'name email');
  res.json({ event: serializeEvent(event, req.user, { withParticipants: true }) });
};

export const createEvent = async (req, res) => {
  const data = {};
  for (const f of EDITABLE_FIELDS) if (req.body[f] !== undefined) data[f] = req.body[f];
  const event = await Event.create({ ...data, organizer: req.user._id, attendees: [] });
  await event.populate('organizer', ORGANIZER_FIELDS);
  res.status(201).json({ event: serializeEvent(event, req.user) });
};

export const updateEvent = async (req, res) => {
  const event = await findEventOr404(req.params.id);
  assertOrganizer(event, req.user);
  for (const f of EDITABLE_FIELDS) if (req.body[f] !== undefined) event[f] = req.body[f];
  if (event.capacity < event.attendees.length) {
    throw new HttpError(
      400,
      `La capacité ne peut pas être inférieure au nombre d'inscrits (${event.attendees.length})`
    );
  }
  await event.save();
  await event.populate('organizer', ORGANIZER_FIELDS);
  res.json({ event: serializeEvent(event, req.user) });
};

export const deleteEvent = async (req, res) => {
  const event = await findEventOr404(req.params.id);
  assertOrganizer(event, req.user);
  await event.deleteOne();
  res.status(204).end();
};

/** Inscription atomique : la condition (places dispo + pas déjà inscrit) est vérifiée par MongoDB. */
export const registerToEvent = async (req, res) => {
  assertValidId(req.params.id);
  const userId = req.user._id;
  const updated = await Event.findOneAndUpdate(
    {
      _id: req.params.id,
      organizer: { $ne: userId },
      attendees: { $ne: userId },
      date: { $gte: new Date() },
      $expr: { $lt: [{ $size: '$attendees' }, '$capacity'] },
    },
    { $addToSet: { attendees: userId } },
    { new: true }
  ).populate('organizer', ORGANIZER_FIELDS);

  if (!updated) {
    const event = await Event.findById(req.params.id);
    if (!event) throw new HttpError(404, 'Événement introuvable');
    if (event.organizer.toString() === userId.toString()) {
      throw new HttpError(409, 'Vous êtes l\'organisateur de cet événement');
    }
    if (event.attendees.some((a) => a.toString() === userId.toString())) {
      throw new HttpError(409, 'Vous êtes déjà inscrit à cet événement');
    }
    if (event.date < new Date()) throw new HttpError(409, 'Cet événement est déjà passé');
    throw new HttpError(409, 'Cet événement est complet');
  }
  res.json({ event: serializeEvent(updated, req.user) });
};

export const unregisterFromEvent = async (req, res) => {
  assertValidId(req.params.id);
  const userId = req.user._id;
  const updated = await Event.findOneAndUpdate(
    { _id: req.params.id, attendees: userId },
    { $pull: { attendees: userId } },
    { new: true }
  ).populate('organizer', ORGANIZER_FIELDS);
  if (!updated) {
    const exists = await Event.exists({ _id: req.params.id });
    if (!exists) throw new HttpError(404, 'Événement introuvable');
    throw new HttpError(409, "Vous n'êtes pas inscrit à cet événement");
  }
  res.json({ event: serializeEvent(updated, req.user) });
};

export const myEvents = async (req, res) => {
  const events = await Event.find({ organizer: req.user._id })
    .sort({ date: -1 })
    .populate('organizer', ORGANIZER_FIELDS);
  res.json({ events: events.map((e) => serializeEvent(e, req.user)) });
};

export const myRegistrations = async (req, res) => {
  const events = await Event.find({ attendees: req.user._id })
    .sort({ date: 1 })
    .populate('organizer', ORGANIZER_FIELDS);
  res.json({ events: events.map((e) => serializeEvent(e, req.user)) });
};

export const listCategories = (_req, res) => {
  res.json({ categories: Event.schema.path('category').enumValues });
};
