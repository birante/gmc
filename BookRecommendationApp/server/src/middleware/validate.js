import mongoose from 'mongoose';
import { validationResult } from 'express-validator';
import { HttpError } from '../utils/httpError.js';

export function validate(req, _res, next) {
  const result = validationResult(req);
  if (!result.isEmpty()) {
    const first = result.array()[0];
    return next(new HttpError(400, first.msg));
  }
  next();
}

export function validObjectId(param = 'id') {
  return (req, _res, next) => {
    if (!mongoose.isValidObjectId(req.params[param])) return next(new HttpError(404, 'Ressource introuvable'));
    next();
  };
}
