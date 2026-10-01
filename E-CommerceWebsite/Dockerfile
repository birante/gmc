# syntax=docker/dockerfile:1
# Le build React est indépendant de l'architecture : on le fait en natif (esbuild plante sous émulation QEMU).
FROM --platform=$BUILDPLATFORM node:22-alpine AS client-build
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

FROM node:22-alpine AS server-deps
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci --omit=dev

FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=server-deps /app/server/node_modules ./server/node_modules
COPY server/package.json ./server/package.json
COPY server/src ./server/src
COPY --from=client-build /app/client/dist ./client/dist
RUN chown -R node:node /app
USER node
EXPOSE 3000
CMD ["node","server/src/index.js"]
