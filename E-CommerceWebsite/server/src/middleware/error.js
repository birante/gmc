import mongoose from 'mongoose';

export function notFound(req, res) {
  res.status(404).json({ error: `Route introuvable : ${req.method} ${req.originalUrl}` });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  let status = err.status || 500;
  let message = err.message || 'Erreur serveur';

  if (err instanceof mongoose.Error.ValidationError) {
    status = 400;
    message = Object.values(err.errors)[0]?.message || 'Données invalides';
  } else if (err instanceof mongoose.Error.CastError) {
    status = 400;
    message = 'Identifiant invalide';
  } else if (err.code === 11000) {
    status = 409;
    message = 'Cette ressource existe déjà';
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'JSON invalide';
  }

  if (status >= 500) {
    if (process.env.NODE_ENV !== 'test') console.error(err);
    if (process.env.NODE_ENV === 'production') message = 'Erreur serveur';
  }
  res.status(status).json({ error: message });
}
