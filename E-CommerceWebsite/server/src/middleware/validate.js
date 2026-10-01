import { HttpError } from '../utils/httpError.js';

export const validate = (schema, source = 'body') => (req, _res, next) => {
  const result = schema.safeParse(req[source]);
  if (!result.success) {
    const issue = result.error.issues[0];
    const field = issue.path.join('.');
    return next(new HttpError(400, field ? `${field} : ${issue.message}` : issue.message));
  }
  if (source === 'body') req.body = result.data;
  else req.validated = result.data;
  next();
};
