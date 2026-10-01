import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 80 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['client', 'admin'], default: 'client' }
  },
  { timestamps: true }
);

userSchema.methods.checkPassword = function (password) {
  return bcrypt.compare(password, this.passwordHash);
};

userSchema.statics.hashPassword = (password) => bcrypt.hash(password, 10);

userSchema.methods.toJSON = function () {
  return { id: this._id, name: this.name, email: this.email, role: this.role, createdAt: this.createdAt };
};

export const User = mongoose.model('User', userSchema);
