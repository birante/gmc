import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, unique: true, trim: true, minlength: 3, maxlength: 30 },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    passwordHash: { type: String, required: true, select: false },
    bio: { type: String, default: '', maxlength: 500 },
    favoriteGenres: [{ type: String, trim: true }],
    following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

userSchema.methods.toPublic = function toPublic() {
  return {
    id: this._id.toString(),
    username: this.username,
    email: this.email,
    bio: this.bio,
    favoriteGenres: this.favoriteGenres,
    followingCount: this.following?.length || 0,
    followersCount: this.followers?.length || 0,
    following: (this.following || []).map((f) => (f._id || f).toString()),
    createdAt: this.createdAt,
  };
};

export default mongoose.model('User', userSchema);
