// Operational error class — anything thrown with `new AppError(msg, code)`
// is trusted enough to be shown to the client. Anything else is treated
// as a programmer / infrastructure error and hidden by the error handler.

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
