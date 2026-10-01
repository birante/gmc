import { validationResult } from 'express-validator';

export function validate(req, res, next) {
  const result = validationResult(req);
  if (!result.isEmpty()) {
    const errors = result.array();
    return res.status(400).json({ error: errors[0].msg, details: errors.map((e) => ({ field: e.path, message: e.msg })) });
  }
  next();
}
