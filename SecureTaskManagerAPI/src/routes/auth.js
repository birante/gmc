const express = require("express");
const passport = require("passport");
const catchAsync = require("../utils/catchAsync");
const AppError = require("../utils/AppError");
const verifyToken = require("../middleware/verifyToken");
const { loginLimiter } = require("../middleware/rateLimiters");
const auth = require("../controllers/authController");
const { isGoogleConfigured } = require("../config/passport");

const router = express.Router();

router.post("/signup", catchAsync(auth.signup));
router.post("/login",  loginLimiter, catchAsync(auth.login));
router.post("/logout", catchAsync(auth.logout));
router.get ("/me",     verifyToken, catchAsync(auth.me));

// --- Google OAuth (only mounted if credentials are configured) -------
if (isGoogleConfigured()) {
  router.get("/google",
    passport.authenticate("google", { scope: ["profile", "email"], session: false }));

  router.get("/google/callback",
    passport.authenticate("google", { failureRedirect: "/auth/google/failure", session: false }),
    catchAsync(auth.googleCallbackSuccess));

  router.get("/google/failure", (req, res) => {
    res.status(401).json({ error: "Google authentication failed" });
  });
} else {
  const notConfigured = (req, res, next) =>
    next(new AppError("Google OAuth is not configured — set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET", 501));
  router.get("/google",           notConfigured);
  router.get("/google/callback",  notConfigured);
}

module.exports = router;
