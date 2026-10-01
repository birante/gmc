# syntax=docker/dockerfile:1
# Multi-stage image: builds the React front-end and the API, ships a slim runtime
# that serves both from one container (portable to Render, Azure Container Apps,
# Google Cloud Run, AWS App Runner/ECS...).

FROM node:22-bookworm-slim AS base
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# ---- dependencies (cached while package files are unchanged) ----
FROM base AS deps
COPY package.json package-lock.json ./
COPY apps/api/package.json apps/api/
COPY apps/web/package.json apps/web/
COPY apps/api/prisma apps/api/prisma
RUN npm ci

# ---- build ----
FROM deps AS build
COPY . .
RUN npm run build && npm prune --omit=dev

# ---- runtime ----
FROM base AS runtime
ENV NODE_ENV=production \
    PORT=4000 \
    WEB_DIST_DIR=/app/apps/web/dist
COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/package.json ./
COPY --from=build --chown=node:node /app/apps/api/package.json ./apps/api/
COPY --from=build --chown=node:node /app/apps/api/dist ./apps/api/dist
COPY --from=build --chown=node:node /app/apps/api/prisma ./apps/api/prisma
COPY --from=build --chown=node:node /app/apps/web/dist ./apps/web/dist
USER node
WORKDIR /app/apps/api
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s CMD node -e "fetch('http://localhost:'+process.env.PORT+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
# Apply pending migrations, then start the server.
CMD ["sh", "-c", "/app/node_modules/.bin/prisma migrate deploy && exec node dist/server.js"]
