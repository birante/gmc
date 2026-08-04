const bcrypt = require("bcryptjs");
const AppError = require("../utils/AppError");
const User = require("../models/User");
const { signToken, setAuthCookie, clearAuthCookie } = require("../utils/jwt");

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASS = 8;

function validateCredentials({ email, password }) {
  if (typeof email !== "string" || !EMAIL_REGEX.test(email)) {
    throw new AppError("A valid email is required", 400);
  }
  if (typeof password !== "string" || password.length < MIN_PASS) {
    throw new AppError(`Password must be at least ${MIN_PASS} characters`, 400);
  }
}

async function signup(req, res) {
  const { email, password } = req.body || {};
  validateCredentials({ email, password });

  const existing = await User.findByEmail(email);
  if (existing) throw new AppError("Email already registered", 409);

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await User.create({ email, passwordHash });

  const token = signToken(user);
  setAuthCookie(res, token);
  res.status(201).json({ user: safeUser(user) });
}

async function login(req, res) {
  const { email, password } = req.body || {};
  validateCredentials({ email, password });

  const user = await User.findByEmail(email);
  // Always run bcrypt to reduce timing signal for "user exists".
  const ok = user?.passwordHash
    ? await bcrypt.compare(password, user.passwordHash)
    : await bcrypt.compare(password, "$2b$12$" + "z".repeat(53));

  if (!user || !ok) throw new AppError("Invalid credentials", 401);

  const token = signToken(user);
  setAuthCookie(res, token);
  res.json({ user: safeUser(user) });
}

async function logout(req, res) {
  clearAuthCookie(res);
  res.json({ ok: true });
}

async function me(req, res) {
  const user = await User.findById(req.user.id);
  if (!user) throw new AppError("User not found", 404);
  res.json({ user: safeUser(user) });
}

// Mounted by routes/auth.js AFTER passport's Google callback succeeds.
async function googleCallbackSuccess(req, res) {
  const token = signToken(req.user);
  setAuthCookie(res, token);
  res.json({ user: safeUser(req.user), message: "Google login successful." });
}

function safeUser(user) {
  return { id: user.id, email: user.email, displayName: user.displayName };
}

module.exports = { signup, login, logout, me, googleCallbackSuccess };
