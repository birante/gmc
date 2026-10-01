# VaxTrack - Deployment guide

VaxTrack deploys as **one Node.js web service plus one managed PostgreSQL database**. The web service serves the REST API under `/api` and the compiled React app on every other path. The primary target is **Render** (free tier, Blueprint in `render.yaml`). Alternatives follow: Vercel for the front-end, and Docker for Azure, GCP or AWS.

---

## 1. Prerequisites

- The code pushed to GitHub (`git@github.com:birante/gmc.git`, folder `CloudBasedWebSystemDesign/`).
- A Render account linked to GitHub (https://dashboard.render.com).
- Locally, to test before deploying: Node 22 and PostgreSQL 15 or later (or Docker).

## 2. Deploy on Render with the Blueprint (recommended)

1. **Push the code**
   ```bash
   cd /Users/macbook/Codes/GOMYCODE/gmc
   git add CloudBasedWebSystemDesign .github/workflows/cloud-web-system-ci.yml
   git commit -m "Add VaxTrack cloud-based web system (capstone)"
   git push origin main
   ```
2. **Create the Blueprint.** In Render, go to **New + -> Blueprint** and select the `birante/gmc` repository.
3. **Blueprint path.** The repository is a monorepo, so set **Blueprint Path** to `CloudBasedWebSystemDesign/render.yaml`.
4. **Secrets.** Render asks for the values marked `sync: false`:
   - `ADMIN_PASSWORD`: the password of the first administrator (`admin@vaxtrack.sn`). Use a strong value.
5. Click **Apply**. Render then:
   - creates the PostgreSQL instance `vaxtrack-db` (Frankfurt) and injects `DATABASE_URL`;
   - generates a random `JWT_SECRET`;
   - builds the app with `npm ci --include=dev && npm run build` from `rootDir: CloudBasedWebSystemDesign`;
   - starts it with `npm run start:prod`, which runs `prisma migrate deploy` and then `node dist/server.js`;
   - on first boot, seeds the vaccination schedule, the administrator and demo data (`SEED_ON_START=true`). The seed is idempotent and safe on every restart;
   - waits for `GET /health` to return 200 before routing traffic.
6. **Check the deployment.** Open `https://<service-name>.onrender.com`:
   ```bash
   URL=https://vaxtrack.onrender.com     # replace with your URL
   curl -s $URL/health
   curl -s -X POST $URL/api/public/lookup -H 'Content-Type: application/json' \
        -d '{"referenceCode":"VX-DEMO-2026","phoneLast4":"4567"}'
   open $URL/api/docs                     # Swagger UI
   ```
7. **CORS.** CORS matters only if another origin calls the API. If your service URL is not `https://vaxtrack.onrender.com`, update the `CORS_ORIGINS` environment variable. Same-origin calls from the bundled SPA do not need it.

> Free-tier notes: a free web service sleeps after about 15 minutes without traffic, so the first request then takes about 30-60 s (open the URL a minute before a demo). Free PostgreSQL databases expire after a limited period (30 days at the time of writing); upgrade the database plan for anything beyond a demo.

### Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DATABASE_URL` | yes | from Blueprint | PostgreSQL connection string |
| `JWT_SECRET` | yes | generated | HMAC secret, at least 32 characters |
| `JWT_EXPIRES_IN` | no | `8h` | Token lifetime (one clinic shift) |
| `NODE_ENV` | yes | `production` | Enables production logging |
| `PORT` | no | set by Render | HTTP port |
| `CORS_ORIGINS` | no | `http://localhost:5173` | Comma-separated allowed origins |
| `WEB_DIST_DIR` | no | `../web/dist` | Built SPA to serve; empty means API only |
| `SEED_ON_START` | no | `false` | Run the idempotent seed at boot |
| `SEED_DEMO_DATA` | no | `false` | Also create demo clinics, nurses and 60 children |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | first boot | - | First administrator account |
| `REMINDER_WINDOW_DAYS` | no | `3` | Days ahead for SMS reminders |
| `RATE_LIMIT_MAX` | no | `300` | Requests per 15 min per IP on `/api` |
| `LOG_LEVEL` | no | `info` | pino log level |

### Database migrations

- Migrations live in `apps/api/prisma/migrations` and are committed.
- **Production:** `prisma migrate deploy` runs automatically at each start and is a no-op when the database is up to date. On a paid plan you can move it to Render's *Pre-Deploy Command* (`npm run db:deploy`).
- **New migration (development):** edit `schema.prisma`, run `npm run db:migrate -- --name <change>`, commit the generated folder and push.
- **Rollback:** Prisma has no automatic down-migrations. Write a new forward migration, or restore a database backup (paid plans include point-in-time recovery).

### Custom domain

1. In the service, open **Settings -> Custom Domains -> Add** and enter, for example, `vaxtrack.example.sn`.
2. At your DNS provider, create a `CNAME` from `vaxtrack` to `<service>.onrender.com` (or the `A`/`ALIAS` record Render shows for an apex domain).
3. Render issues a Let's Encrypt TLS certificate automatically.
4. Add the new origin to `CORS_ORIGINS` if other front-ends call the API.

### Operations

- **Logs:** Render dashboard -> Logs. The logs are JSON lines from pino, filterable by `req.id`.
- **Health:** `/health` returns `{"status":"ok","database":"up","commit":"abc1234"}`. Point an uptime monitor (UptimeRobot or Better Stack) at it.
- **Scaling:** raise the instance type or the instance count (paid plans). The API is stateless (JWT, no session store), so horizontal scaling needs no code change.
- **Rollback a release:** Render -> Events -> pick a previous deploy -> *Rollback*.

## 3. Alternative: front-end on Vercel, API on Render

1. Deploy the Render Blueprint as above (it still serves the SPA, which does no harm).
2. In Vercel, go to **Add New -> Project**, import `birante/gmc`, and set:
   - **Root Directory:** `CloudBasedWebSystemDesign/apps/web`
   - **Framework preset:** Vite. Build command `npm run build`, output `dist`.
   - **Environment variable:** `VITE_API_URL=https://vaxtrack.onrender.com`
3. `apps/web/vercel.json` already rewrites every path to `index.html` (client-side routing).
4. On Render, set `CORS_ORIGINS=https://<project>.vercel.app` and redeploy.

> Because the web workspace has no runtime dependency on the API workspace, Vercel can build it on its own. If Vercel complains about the lockfile, set the install command to `npm install`.

## 4. Alternative: Docker (Azure, GCP, AWS, any VM)

```bash
docker build -t vaxtrack .
docker run -p 4000:4000 \
  -e DATABASE_URL='postgresql://user:pass@host:5432/vaxtrack?sslmode=require' \
  -e JWT_SECRET="$(openssl rand -hex 32)" \
  -e SEED_ON_START=true -e ADMIN_PASSWORD='StrongPass!2026' \
  vaxtrack
```

The container runs migrations, then starts as the unprivileged `node` user, and has a `HEALTHCHECK` on `/health`.

- **Azure Container Apps:** `az containerapp up --name vaxtrack --source . --ingress external --target-port 4000 --env-vars ...` with Azure Database for PostgreSQL Flexible Server.
- **Google Cloud Run:** `gcloud run deploy vaxtrack --source . --port 4000 --set-env-vars ...` with Cloud SQL for PostgreSQL.
- **AWS App Runner:** push the image to ECR, create an App Runner service on port 4000, and use Amazon RDS for PostgreSQL.

## 5. Running locally

**Option A: Docker Compose (whole stack)**
```bash
docker compose up --build
# http://localhost:4000  (admin@vaxtrack.sn / ChangeMe!2026, infirmier.yoff@vaxtrack.sn / Demo!2026)
```

**Option B: Node + local PostgreSQL (hot reload)**
```bash
npm install
cp apps/api/.env.example apps/api/.env      # set DATABASE_URL and JWT_SECRET
npm run db:migrate                          # create the schema
npm run db:seed                             # schedule + admin + demo data
npm run dev                                 # API :4000 + Vite :5173 (proxied /api)
```

## 6. Production checklist

- [ ] `SEED_DEMO_DATA=false` and a strong `ADMIN_PASSWORD` (change it after the first login)
- [ ] Paid PostgreSQL plan with backups for real patient data
- [ ] Custom domain over HTTPS, `CORS_ORIGINS` restricted to it
- [ ] Real SMS provider adapter configured (`SmsNotifier`)
- [ ] Data-protection declaration to Senegal's Commission de Protection des Donnees Personnelles (CDP) before processing real health data
- [ ] Uptime monitor on `/health` and log retention configured
