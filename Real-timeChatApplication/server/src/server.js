import http from 'node:http';
import { createApp } from './app.js';
import { attachSockets } from './sockets/index.js';

/** Crée l'app Express + le serveur HTTP + Socket.IO (sans listen). */
export function createServer() {
  const app = createApp();
  const server = http.createServer(app);
  const { io, presence } = attachSockets(server);
  app.set('io', io);
  app.set('presence', presence);
  return { app, server, io, presence };
}
