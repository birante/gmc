import { badRequest } from '../utils/httpError.js';

export const validate = (schema, source = 'body') => (req, _res, next) => {
  const result = schema.safeParse(req[source] ?? {});
  if (!result.success) {
    const msg = result.error.issues.map((i) => i.message).join(', ');
    return next(badRequest(msg));
  }
  req.validated = { ...(req.validated || {}), [source]: result.data };
  next();
};
