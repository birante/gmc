import Recommendation from '../models/Recommendation.js';
import { serializeRecommendations } from '../utils/serialize.js';

const DAY = 24 * 60 * 60 * 1000;

/**
 * Score de pertinence :
 *  - récence : 10 points décroissant de moitié tous les 3 jours
 *  - popularité : 2 points par like (plafonné), + 0.5 par commentaire
 *  - personne suivie : +8 ; genre favori : +5 ; livre bien noté : +1
 */
export function scoreRecommendation(rec, { followingIds, favoriteGenres, now = Date.now(), commentsCount = 0 }) {
  const reasons = [];
  const ageDays = Math.max(0, (now - new Date(rec.createdAt).getTime()) / DAY);
  let score = 10 * Math.pow(0.5, ageDays / 3);
  const likes = rec.likes?.length || 0;
  score += Math.min(likes, 25) * 2 + Math.min(commentsCount, 20) * 0.5;

  const authorId = (rec.user?._id || rec.user).toString();
  if (followingIds.has(authorId)) {
    score += 8;
    reasons.push('following');
  }
  const genres = (rec.book?.genres || []).map((g) => g.toLowerCase());
  if (genres.some((g) => favoriteGenres.some((f) => g.includes(f) || f.includes(g)))) {
    score += 5;
    reasons.push('genre');
  }
  if (likes >= 2) reasons.push('popular');
  if ((rec.book?.averageRating || 0) >= 4) score += 1;
  if (!reasons.length) reasons.push('discover');
  return { score: Math.round(score * 100) / 100, reasons };
}

export async function getFeed(req, res) {
  const user = req.user;
  const limit = Math.min(Number(req.query.limit) || 20, 50);
  const page = Math.max(Number(req.query.page) || 1, 1);
  const followingIds = new Set(user.following.map((id) => id.toString()));
  const favoriteGenres = (user.favoriteGenres || []).map((g) => g.toLowerCase());

  // Candidats : recommandations récentes des autres lecteurs (fenêtre bornée).
  const candidates = await Recommendation.find({ user: { $ne: user._id } })
    .sort({ createdAt: -1 })
    .limit(300)
    .populate('user', 'username')
    .populate('book');

  const serialized = await serializeRecommendations(candidates, user._id);
  const now = Date.now();
  const scored = candidates
    .map((rec, i) => ({ rec, data: serialized[i], ...scoreRecommendation(rec, { followingIds, favoriteGenres, now, commentsCount: serialized[i].commentsCount }) }))
    .filter((x) => x.data.book);
  scored.sort((a, b) => b.score - a.score);

  const slice = scored.slice((page - 1) * limit, page * limit);
  res.json({
    recommendations: slice.map((x) => ({ ...x.data, score: x.score, reasons: x.reasons })),
    page,
    hasMore: scored.length > page * limit,
  });
}
