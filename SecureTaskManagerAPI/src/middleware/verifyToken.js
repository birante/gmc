// Reads the JWT from the HTTP-only cookie (preferred) or the
// Authorization: Bearer header, verifies it, and attaches req.user.

const AppError = require("../utils/AppError");
const { verifyTokenValue, COOKIE_NAME } = require("../utils/jwt");

function verifyToken(req, res, next) {
  const cookieToken = req.cookies?.[COOKIE_NAME];
  const authHeader  = req.headers.authorization ?? "";
  const bearerToken = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
  const token = cookieToken || bearerToken;

  if (!token) return next(new AppError("Authentication required", 401));

  try {
    const payload = verifyTokenValue(token);
    req.user = { id: payload.sub, email: payload.email };
    return next();
  } catch (err) {
    return next(new AppError("Invalid or expired token", 401));
  }
}

module.exports = verifyToken;
