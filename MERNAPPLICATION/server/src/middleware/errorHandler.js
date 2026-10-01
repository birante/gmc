import mongoose from 'mongoose';

export const notFoundApi = (req, res) => {
  res.status(404).json({ error: `Route introuvable : ${req.method} ${req.originalUrl}` });
};

// eslint-disable-next-line no-unused-vars
export const errorHandler = (err, req, res, _next) => {
  if (err instanceof mongoose.Error.CastError) {
    return res.status(404).json({ error: 'Ressource introuvable' });
  }
  if (err instanceof mongoose.Error.ValidationError) {
    const first = Object.values(err.errors)[0];
    return res.status(400).json({ error: first?.message || 'Données invalides' });
  }
  if (err?.code === 11000) {
    return res.status(409).json({ error: 'Cette ressource existe déjà' });
  }
  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'JSON invalide' });
  }
  const status = err.status || 500;
  if (status >= 500 && process.env.NODE_ENV !== 'test') console.error(err);
  return res.status(status).json({ error: status >= 500 ? 'Erreur interne du serveur' : err.message });
};
