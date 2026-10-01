import mongoose from 'mongoose';

const ratingSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    value: { type: Number, required: true, min: 1, max: 5 },
  },
  { _id: false, timestamps: true }
);

const bookSchema = new mongoose.Schema(
  {
    // Identifiant d'une source externe (ex. « ol:/works/OL45804W » pour Open Library)
    externalId: { type: String, trim: true, index: { unique: true, sparse: true } },
    // Origine de la fiche : saisie dans BookNest ou importée depuis Open Library
    source: { type: String, enum: ['booknest', 'openlibrary'], default: 'booknest' },
    title: { type: String, required: true, trim: true },
    authors: [{ type: String, trim: true }],
    genres: [{ type: String, trim: true }],
    description: { type: String, default: '' },
    coverUrl: { type: String, default: '' },
    isbn: { type: String, default: '' },
    publishedDate: { type: String, default: '' },
    pageCount: { type: Number },
    ratings: [ratingSchema],
    averageRating: { type: Number, default: 0 },
    ratingsCount: { type: Number, default: 0 },
    addedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

bookSchema.index({ title: 'text', authors: 'text', genres: 'text' });

bookSchema.methods.recomputeRating = function recomputeRating() {
  this.ratingsCount = this.ratings.length;
  const sum = this.ratings.reduce((s, r) => s + r.value, 0);
  this.averageRating = this.ratingsCount ? Math.round((sum / this.ratingsCount) * 10) / 10 : 0;
};

/** Ajoute ou met à jour le vote d'un utilisateur (un vote par utilisateur). */
bookSchema.methods.setUserRating = function setUserRating(userId, value) {
  const existing = this.ratings.find((r) => r.user.toString() === userId.toString());
  if (existing) existing.value = value;
  else this.ratings.push({ user: userId, value });
  this.recomputeRating();
};

bookSchema.methods.toPublic = function toPublic(userId) {
  const mine = userId ? this.ratings.find((r) => r.user.toString() === userId.toString()) : null;
  return {
    id: this._id.toString(),
    externalId: this.externalId || null,
    source: this.source || 'booknest',
    title: this.title,
    authors: this.authors,
    genres: this.genres,
    description: this.description,
    coverUrl: this.coverUrl,
    isbn: this.isbn,
    publishedDate: this.publishedDate,
    pageCount: this.pageCount,
    averageRating: this.averageRating,
    ratingsCount: this.ratingsCount,
    myRating: mine ? mine.value : null,
    addedBy: this.addedBy ? this.addedBy.toString() : null,
    canEdit: Boolean(userId && this.addedBy && this.addedBy.toString() === userId.toString()),
  };
};

export default mongoose.model('Book', bookSchema);
