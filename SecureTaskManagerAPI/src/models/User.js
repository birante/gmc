// In-memory user store. Same async surface a Mongoose model would give,
// so swapping in MongoDB later is a mechanical change.

const crypto = require("crypto");

const usersById       = new Map();   // id -> user
const usersByEmail    = new Map();   // email (lowercase) -> user
const usersByGoogleId = new Map();   // googleId -> user

function newId() { return crypto.randomUUID(); }

async function findByEmail(email) {
  if (!email) return null;
  return usersByEmail.get(String(email).toLowerCase()) ?? null;
}

async function findById(id) {
  return usersById.get(id) ?? null;
}

async function findByGoogleId(googleId) {
  return usersByGoogleId.get(googleId) ?? null;
}

async function create({ email, passwordHash = null, googleId = null, displayName = null }) {
  const emailLc = String(email).toLowerCase();
  if (usersByEmail.has(emailLc)) {
    throw new Error("Email already registered");
  }
  const user = {
    id: newId(),
    email: emailLc,
    passwordHash,
    googleId,
    displayName: displayName ?? emailLc,
    createdAt: new Date(),
  };
  usersById.set(user.id, user);
  usersByEmail.set(user.email, user);
  if (googleId) usersByGoogleId.set(googleId, user);
  return user;
}

async function linkGoogleId(user, googleId) {
  user.googleId = googleId;
  usersByGoogleId.set(googleId, user);
  return user;
}

// Test-only reset (used by tests/smoke.js).
function _reset() {
  usersById.clear();
  usersByEmail.clear();
  usersByGoogleId.clear();
}

module.exports = { findByEmail, findById, findByGoogleId, create, linkGoogleId, _reset };
