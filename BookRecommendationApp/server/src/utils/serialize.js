import Comment from '../models/Comment.js';

export function serializeBookShort(book) {
  if (!book) return null;
  return {
    id: book._id.toString(),
    title: book.title,
    authors: book.authors,
    genres: book.genres,
    coverUrl: book.coverUrl,
    averageRating: book.averageRating,
    ratingsCount: book.ratingsCount,
  };
}

export function serializeUserShort(user) {
  if (!user) return null;
  return { id: user._id.toString(), username: user.username };
}

/** Sérialise une liste de recommandations (populées user + book) avec nb de commentaires. */
export async function serializeRecommendations(recs, viewerId) {
  const ids = recs.map((r) => r._id);
  const counts = ids.length
    ? await Comment.aggregate([{ $match: { recommendation: { $in: ids } } }, { $group: { _id: '$recommendation', n: { $sum: 1 } } }])
    : [];
  const countMap = new Map(counts.map((c) => [c._id.toString(), c.n]));
  return recs.map((r) => ({
    id: r._id.toString(),
    user: serializeUserShort(r.user),
    book: serializeBookShort(r.book),
    review: r.review,
    rating: r.rating,
    likesCount: r.likes.length,
    likedByMe: viewerId ? r.likes.some((l) => l.toString() === viewerId.toString()) : false,
    commentsCount: countMap.get(r._id.toString()) || 0,
    createdAt: r.createdAt,
    ...(r.score !== undefined ? { score: r.score, reasons: r.reasons } : {}),
  }));
}
