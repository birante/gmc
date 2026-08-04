// JWT signing + cookie helpers. Every route that mints a token goes
// through here so cookie flags stay consistent.

const jwt = require("jsonwebtoken");

const JWT_SECRET     = process.env.JWT_SECRET     || "dev-secret-change-me";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "7d";
const COOKIE_NAME    = "token";
const COOKIE_MAX_AGE = 7 * 24 * 60 * 60 * 1000;   // 7 days

function signToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

function verifyTokenValue(token) {
  return jwt.verify(token, JWT_SECRET);
}

function setAuthCookie(res, token) {
  res.cookie(COOKIE_NAME, token, {
    httpOnly: true,
    secure:   process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge:   COOKIE_MAX_AGE,
  });
}

function clearAuthCookie(res) {
  res.clearCookie(COOKIE_NAME, {
    httpOnly: true,
    secure:   process.env.NODE_ENV === "production",
    sameSite: "strict",
  });
}

module.exports = { signToken, verifyTokenValue, setAuthCookie, clearAuthCookie, COOKIE_NAME };
