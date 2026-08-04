// Passport strategies. The Google strategy is only registered when
// GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET are set — the app still
// boots cleanly without them, and /auth/google returns 501 in that case.

const passport = require("passport");
const GoogleStrategy = require("passport-google-oauth20").Strategy;
const User = require("../models/User");

function isGoogleConfigured() {
  return Boolean(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET);
}

function configurePassport() {
  passport.serializeUser((user, done) => done(null, user.id));
  passport.deserializeUser(async (id, done) => {
    try { done(null, await User.findById(id)); }
    catch (err) { done(err); }
  });

  if (!isGoogleConfigured()) return;

  passport.use(new GoogleStrategy(
    {
      clientID:     process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL:  process.env.GOOGLE_CALLBACK_URL || "http://localhost:3000/auth/google/callback",
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails?.[0]?.value?.toLowerCase();
        if (!email) return done(new Error("Google profile has no email"));

        let user = await User.findByGoogleId(profile.id);
        if (user) return done(null, user);

        user = await User.findByEmail(email);
        if (user) {
          await User.linkGoogleId(user, profile.id);
          return done(null, user);
        }
        user = await User.create({ email, googleId: profile.id, displayName: profile.displayName });
        return done(null, user);
      } catch (err) {
        return done(err);
      }
    },
  ));
}

module.exports = { configurePassport, isGoogleConfigured };
