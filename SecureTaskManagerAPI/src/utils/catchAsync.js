// Wraps an async route handler so any rejection is forwarded to Express's
// error middleware instead of becoming an unhandled promise rejection.
//
// Usage:
//   router.get("/x", catchAsync(async (req, res) => { ... }))

module.exports = function catchAsync(fn) {
  return function (req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
