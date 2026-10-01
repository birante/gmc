import mongoose from 'mongoose';
import Book from '../models/Book.js';
import Comment from '../models/Comment.js';
import Recommendation from '../models/Recommendation.js';
import { HttpError } from '../utils/httpError.js';
import { serializeRecommendations, serializeUserShort } from '../utils/serialize.js';
import { findOrCreateBook } from './bookController.js';

async function loadRec(id) {
  const rec = await Recommendation.findById(id);
  if (!rec) throw new HttpError(404, 'Recommandation introuvable');
  return rec;
}

async function serializeOne(id, viewerId) {
  const rec = await Recommendation.findById(id).populate('user', 'username').populate('book');
  return (await serializeRecommendations([rec], viewerId))[0];
}

export async function listRecommendations(req, res) {
  const filter = {};
  if (req.query.user && mongoose.isValidObjectId(req.query.user)) filter.user = req.query.user;
  if (req.query.book && mongoose.isValidObjectId(req.query.book)) filter.book = req.query.book;
  const limit = Math.min(Number(req.query.limit) || 20, 50);
  const page = Math.max(Number(req.query.page) || 1, 1);
  const recs = await Recommendation.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('user', 'username')
    .populate('book');
  res.json({ recommendations: await serializeRecommendations(recs, req.user?._id), page });
}

export async function getRecommendation(req, res) {
  await loadRec(req.params.id);
  const recommendation = await serializeOne(req.params.id, req.user?._id);
  const comments = await Comment.find({ recommendation: req.params.id }).sort({ createdAt: 1 }).populate('user', 'username');
  res.json({ recommendation, comments: comments.map(serializeComment) });
}

/**
 * Crée une recommandation. Le livre peut être désigné par :
 *  - bookId (livre déjà en base), externalId (résultat Open Library, importé), ou
 *  - les champs saisis à la main (title, authors, description, genres...).
 * La note de la recommandation compte aussi comme vote sur le livre.
 */
export async function createRecommendation(req, res) {
  const { bookId, book: bookData = {}, review, rating } = req.body;
  let book;
  if (bookId) {
    if (!mongoose.isValidObjectId(bookId)) throw new HttpError(404, 'Livre introuvable');
    book = await Book.findById(bookId);
    if (!book) throw new HttpError(404, 'Livre introuvable');
  } else {
    ({ book } = await findOrCreateBook(bookData, req.user._id));
  }
  const already = await Recommendation.findOne({ user: req.user._id, book: book._id });
  if (already) throw new HttpError(409, 'Vous avez déjà recommandé ce livre');

  const rec = await Recommendation.create({ user: req.user._id, book: book._id, review, rating });
  const fresh = await Book.findById(book._id);
  fresh.setUserRating(req.user._id, rating);
  await fresh.save();
  res.status(201).json({ recommendation: await serializeOne(rec._id, req.user._id) });
}

export async function updateRecommendation(req, res) {
  const rec = await loadRec(req.params.id);
  if (!rec.user.equals(req.user._id)) throw new HttpError(403, 'Vous ne pouvez modifier que vos recommandations');
  if (req.body.review !== undefined) rec.review = req.body.review;
  if (req.body.rating !== undefined) {
    rec.rating = req.body.rating;
    const book = await Book.findById(rec.book);
    if (book) {
      book.setUserRating(req.user._id, rec.rating);
      await book.save();
    }
  }
  await rec.save();
  res.json({ recommendation: await serializeOne(rec._id, req.user._id) });
}

export async function deleteRecommendation(req, res) {
  const rec = await loadRec(req.params.id);
  if (!rec.user.equals(req.user._id)) throw new HttpError(403, 'Vous ne pouvez supprimer que vos recommandations');
  await Comment.deleteMany({ recommendation: rec._id });
  await rec.deleteOne();
  res.status(204).end();
}

export async function like(req, res) {
  await loadRec(req.params.id);
  const rec = await Recommendation.findByIdAndUpdate(req.params.id, { $addToSet: { likes: req.user._id } }, { new: true });
  res.json({ liked: true, likesCount: rec.likes.length });
}

export async function unlike(req, res) {
  await loadRec(req.params.id);
  const rec = await Recommendation.findByIdAndUpdate(req.params.id, { $pull: { likes: req.user._id } }, { new: true });
  res.json({ liked: false, likesCount: rec.likes.length });
}

function serializeComment(c) {
  return { id: c._id.toString(), recommendation: c.recommendation.toString(), user: serializeUserShort(c.user), text: c.text, createdAt: c.createdAt };
}

export async function listComments(req, res) {
  await loadRec(req.params.id);
  const comments = await Comment.find({ recommendation: req.params.id }).sort({ createdAt: 1 }).populate('user', 'username');
  res.json({ comments: comments.map(serializeComment) });
}

export async function addComment(req, res) {
  await loadRec(req.params.id);
  const comment = await Comment.create({ recommendation: req.params.id, user: req.user._id, text: req.body.text });
  await comment.populate('user', 'username');
  res.status(201).json({ comment: serializeComment(comment) });
}

export async function deleteComment(req, res) {
  const comment = await Comment.findById(req.params.id);
  if (!comment) throw new HttpError(404, 'Commentaire introuvable');
  const rec = await Recommendation.findById(comment.recommendation);
  const isOwner = comment.user.equals(req.user._id);
  const isRecOwner = rec && rec.user.equals(req.user._id);
  if (!isOwner && !isRecOwner) throw new HttpError(403, 'Vous ne pouvez pas supprimer ce commentaire');
  await comment.deleteOne();
  res.status(204).end();
}
