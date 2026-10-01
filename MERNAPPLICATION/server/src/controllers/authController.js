import { User } from '../models/User.js';
import { signToken } from '../utils/token.js';
import { HttpError } from '../utils/httpError.js';

const authResponse = (user) => ({ token: signToken(user), user: user.toJSON() });

export const register = async (req, res) => {
  const { name, email, password, bio } = req.body;
  const existing = await User.findOne({ email: email.toLowerCase() });
  if (existing) throw new HttpError(409, 'Un compte existe déjà avec cet e-mail');
  const user = new User({ name, email, bio: bio || '' });
  await user.setPassword(password);
  await user.save();
  res.status(201).json(authResponse(user));
};

export const login = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email: email.toLowerCase() });
  if (!user || !(await user.checkPassword(password))) {
    throw new HttpError(401, 'E-mail ou mot de passe incorrect');
  }
  res.json(authResponse(user));
};

// JWT sans état : la déconnexion consiste à supprimer le jeton côté client.
export const logout = (_req, res) => {
  res.status(204).end();
};

export const getMe = (req, res) => {
  res.json({ user: req.user.toJSON() });
};

export const updateMe = async (req, res) => {
  const { name, bio, email, currentPassword, newPassword } = req.body;
  const user = req.user;
  if (name !== undefined) user.name = name;
  if (bio !== undefined) user.bio = bio;
  if (email !== undefined && email.toLowerCase() !== user.email) {
    const taken = await User.findOne({ email: email.toLowerCase(), _id: { $ne: user._id } });
    if (taken) throw new HttpError(409, 'Cet e-mail est déjà utilisé');
    user.email = email;
  }
  if (newPassword) {
    if (!currentPassword || !(await user.checkPassword(currentPassword))) {
      throw new HttpError(400, 'Mot de passe actuel incorrect');
    }
    await user.setPassword(newPassword);
  }
  await user.save();
  res.json({ user: user.toJSON() });
};
