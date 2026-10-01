# syntax=docker/dockerfile:1

# --- Étape 1 : build du client React ---
# Le build React est indépendant de l'architecture : on le fait en natif (esbuild plante sous émulation QEMU).
FROM --platform=$BUILDPLATFORM node:22-alpine AS client-build
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

# --- Étape 2 : dépendances de production du serveur ---
FROM node:22-alpine AS server-deps
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci --omit=dev

# --- Étape 3 : image finale ---
FROM node:22-alpine
ENV NODE_ENV=production PORT=3000
WORKDIR /app
COPY --from=server-deps --chown=node:node /app/server/node_modules ./server/node_modules
COPY --chown=node:node server/package*.json ./server/
COPY --chown=node:node server/src ./server/src
COPY --from=client-build --chown=node:node /app/client/dist ./client/dist
USER node
EXPOSE 3000
CMD ["node", "server/src/index.js"]
