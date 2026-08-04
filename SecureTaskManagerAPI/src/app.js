const express       = require("express");
const helmet         = require("helmet");
const cookieParser   = require("cookie-parser");
const session        = require("express-session");
const mongoSanitize  = require("express-mongo-sanitize");
const xssClean       = require("xss-clean");
const passport       = require("passport");

const { configurePassport } = require("./config/passport");
const { errorHandler, notFound } = require("./middleware/errorHandler");
const { apiLimiter } = require("./middleware/rateLimiters");
const authRoutes  = require("./routes/auth");
const taskRoutes  = require("./routes/tasks");

function createApp() {
  const app = express();

  // --- security headers
  app.use(helmet());

  // --- body parsing
  app.use(express.json({ limit: "100kb" }));
  app.use(cookieParser());

  // --- input sanitization
  //   * mongoSanitize strips $ and . from keys (NoSQL-injection guard)
  //   * xssClean escapes HTML tags in every string value in req.body/query/params
  app.use(mongoSanitize());
  app.use(xssClean());

  // --- session (needed by passport for the OAuth handshake state cookie)
  app.use(session({
    secret: process.env.SESSION_SECRET || "dev-session-secret",
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",  // OAuth redirect back needs lax, not strict
    },
  }));

  // --- passport
  configurePassport();
  app.use(passport.initialize());

  // --- generic rate limit
  app.use(apiLimiter);

  // --- routes
  app.get("/", (req, res) => {
    res.json({
      name: "secure-task-manager-api",
      endpoints: [
        "POST   /auth/signup",
        "POST   /auth/login",
        "POST   /auth/logout",
        "GET    /auth/me",
        "GET    /auth/google",
        "GET    /auth/google/callback",
        "POST   /tasks",
        "GET    /tasks",
        "DELETE /tasks/:id",
      ],
    });
  });
  app.use("/auth",  authRoutes);
  app.use("/tasks", taskRoutes);

  // --- 404 + error handler (LAST)
  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
