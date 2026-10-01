export function notFound(_req, res) {
  res.status(404).json({ error: 'Ressource introuvable' });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'JSON invalide' });
  }
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: Object.values(err.errors)[0]?.message || 'Données invalides' });
  }
  if (err.name === 'CastError') {
    return res.status(404).json({ error: 'Ressource introuvable' });
  }
  if (err.code === 11000) {
    return res.status(409).json({ error: 'Cette ressource existe déjà' });
  }
  const status = err.status || 500;
  if (status >= 500 && process.env.NODE_ENV !== 'test') console.error(err);
  res.status(status).json({ error: status >= 500 ? 'Erreur interne du serveur' : err.message });
}
