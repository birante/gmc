import { config } from '../config.js';

export function notFoundApi(_req, res) {
  res.status(404).json({ error: 'Route introuvable' });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  let status = err.status || err.statusCode || 500;
  let message = err.message || 'Erreur serveur';
  if (err.code === 11000) {
    status = 409;
    message = 'Cette valeur est déjà utilisée';
  } else if (err.name === 'ValidationError') {
    status = 400;
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'JSON invalide';
  }
  if (status >= 500) {
    if (!config.isTest) console.error(err);
    if (config.isProduction) message = 'Erreur serveur';
  }
  res.status(status).json({ error: message });
}
