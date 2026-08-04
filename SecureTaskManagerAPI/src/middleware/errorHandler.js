// Centralised error middleware — the last mount point in app.js.
// - Operational errors (AppError) surface their message and status.
// - Everything else is hidden behind a generic 500 in production
//   (still logged), but shown in full in development.

const AppError = require("../utils/AppError");

function notFound(req, res, next) {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
}

function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const status = err.statusCode ?? 500;
  const isOp   = err.isOperational === true;
  const inDev  = process.env.NODE_ENV !== "production";

  const body = { error: isOp ? err.message : "Internal server error" };
  if (inDev && !isOp) {
    body.stack = err.stack;
  }

  if (!isOp) console.error("[unhandled]", err);
  res.status(status).json(body);
}

module.exports = { errorHandler, notFound };
