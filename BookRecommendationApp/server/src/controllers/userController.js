import mongoose from 'mongoose';
import User from '../models/User.js';
import Recommendation from '../models/Recommendation.js';
import { HttpError } from '../utils/httpError.js';
import { serializeRecommendations } from '../utils/serialize.js';

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export async function listUsers(req, res) {
  const q = (req.query.q || '').trim();
  const filter = q ? { username: new RegExp(escapeRegex(q), 'i') } : {};
  if (req.user) filter._id = { $ne: req.user._id };
  const users = await User.find(filter).sort({ createdAt: -1 }).limit(20);
  res.json({
    users: users.map((u) => ({
      id: u._id.toString(),
      username: u.username,
      bio: u.bio,
      favoriteGenres: u.favoriteGenres,
      followersCount: u.followers.length,
      isFollowing: req.user ? u.followers.some((f) => f.equals(req.user._id)) : false,
    })),
  });
}

export async function getProfile(req, res) {
  const { username } = req.params;
  const query = mongoose.isValidObjectId(username) ? { $or: [{ _id: username }, { username }] } : { username };
  const user = await User.findOne(query).populate('following', 'username').populate('followers', 'username');
  if (!user) throw new HttpError(404, 'Utilisateur introuvable');
  const recs = await Recommendation.find({ user: user._id }).sort({ createdAt: -1 }).limit(50).populate('user', 'username').populate('book');
  const viewerId = req.user?._id;
  res.json({
    user: {
      id: user._id.toString(),
      username: user.username,
      bio: user.bio,
      favoriteGenres: user.favoriteGenres,
      createdAt: user.createdAt,
      following: user.following.map((u) => ({ id: u._id.toString(), username: u.username })),
      followers: user.followers.map((u) => ({ id: u._id.toString(), username: u.username })),
      followingCount: user.following.length,
      followersCount: user.followers.length,
      isFollowing: viewerId ? user.followers.some((f) => f._id.equals(viewerId)) : false,
      isMe: viewerId ? user._id.equals(viewerId) : false,
    },
    recommendations: await serializeRecommendations(recs, viewerId),
  });
}

export async function updateMe(req, res) {
  const { bio, favoriteGenres } = req.body;
  if (bio !== undefined) req.user.bio = bio;
  if (favoriteGenres !== undefined) {
    req.user.favoriteGenres = [...new Set(favoriteGenres.map((g) => String(g).trim()).filter(Boolean))].slice(0, 20);
  }
  await req.user.save();
  res.json({ user: req.user.toPublic() });
}

async function loadTarget(req) {
  const target = await User.findById(req.params.id);
  if (!target) throw new HttpError(404, 'Utilisateur introuvable');
  if (target._id.equals(req.user._id)) throw new HttpError(400, 'Vous ne pouvez pas vous suivre vous-même');
  return target;
}

export async function follow(req, res) {
  const target = await loadTarget(req);
  await User.updateOne({ _id: req.user._id }, { $addToSet: { following: target._id } });
  await User.updateOne({ _id: target._id }, { $addToSet: { followers: req.user._id } });
  const updated = await User.findById(target._id);
  res.json({ following: true, followersCount: updated.followers.length });
}

export async function unfollow(req, res) {
  const target = await loadTarget(req);
  await User.updateOne({ _id: req.user._id }, { $pull: { following: target._id } });
  await User.updateOne({ _id: target._id }, { $pull: { followers: req.user._id } });
  const updated = await User.findById(target._id);
  res.json({ following: false, followersCount: updated.followers.length });
}
