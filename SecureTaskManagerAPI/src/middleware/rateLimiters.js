// Per-route rate limiters. The login route is the one that pays for
// brute-force attacks so it gets the tightest window.

const rateLimit = require("express-rate-limit");

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,   // 15 min
  max: 10,                     // 10 attempts per IP per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many login attempts, please try again later." },
});

// A gentler general-purpose limiter for the whole API.
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Rate limit exceeded." },
});

module.exports = { loginLimiter, apiLimiter };
