# MERN Users App — local & Azure-ready

Minimal MERN stack (**M**ongo + **E**xpress + **R**eact + **N**ode) that
lists / creates / updates / deletes users. Same code runs locally and
on Azure App Service — the only difference is `MONGO_URI` in the env.

## The one-line recap

```bash
export MONGO_URI="mongodb+srv://..."      # your Atlas URI
./scripts/test-atlas.sh                    # verify locally
./scripts/deploy-azure.sh                  # provision on Azure
# then follow the 4 git commands the script prints
```

Full details below.

## Prerequisites

- Node.js **≥ 18**
- Azure CLI (`brew install azure-cli`)
- An Atlas cluster + connection string with your **rotated** password
- (Optional) A local Docker MongoDB for offline testing

## Step 1 — Verify locally

Two options:

**Option A — Atlas (recommended before deploying):**

```bash
cd /Users/macbook/Codes/GOMYCODE/gmc/SystemDesignCloudFundamentalsDeployment/app
export MONGO_URI="mongodb+srv://..."       # your Atlas URI, in THIS shell only
./scripts/test-atlas.sh
```

The URI stays in your shell env — never written to disk, never committed.
The script boots the server, POSTs a user, GETs the list. If you see the
new user, Atlas is wired up. Open http://localhost:3000 to click around.

**Option B — Local Docker Mongo (offline):**

```bash
docker run -d --rm --name mongo -p 27017:27017 mongo:7
cp .env.example .env
npm start
```

`.env` already has the local Mongo URI as default.

## Step 2 — Provision on Azure

Still in the `app/` directory, still with `MONGO_URI` exported in your
shell (recommended — the script picks it up automatically):

```bash
./scripts/deploy-azure.sh
```

The script will:

1. Show you the 4 resources it's about to create and ask `y/N`.
2. Run `az login` if you're not authenticated (browser opens).
3. Pick up `MONGO_URI` from the env (or prompt if not set — silent input).
4. Create the resource group, App Service plan (F1 free), Web App
   (Node 20 on Linux).
5. Set `MONGO_URI`, `NODE_ENV=production`, and
   `SCM_DO_BUILD_DURING_DEPLOYMENT=true` on the Web App.
6. Enable Local Git deployment source and print the git remote URL.

Total time: ~3 minutes.

## Step 3 — Push the code

Local Git deployment needs a git repo whose root is `app/`. Because
`app/` is nested inside the parent `gmc/` repo, the cleanest approach
is to **push from a fresh copy** — that way we don't create a nested
repo inside `gmc/`.

```bash
# make a clean copy outside the parent repo
cp -R /Users/macbook/Codes/GOMYCODE/gmc/SystemDesignCloudFundamentalsDeployment/app ~/mern-azure-deploy
cd ~/mern-azure-deploy

# fresh git repo pointing at Azure
git init
git branch -M master                          # Azure Local Git defaults to master
git add .
git commit -m "MERN app"
git remote add azure <GIT_URL_FROM_STEP_2>
git push azure master
```

The push opens a credentials prompt. Use the App Service **deployment
user** (Portal → your app → *Deployment Center* → *Local Git/FTPS
credentials* → *User scope*). If you've never set one:

```bash
az webapp deployment user set --user-name <choose-a-name> --password <choose-a-password>
```

## Step 4 — Watch it come up

```bash
# in another terminal
az webapp log tail -g rg-mern-birante -n mern-birante-XXXXX
```

You'll see:

- `npm install` (installs Express, Mongoose, Vite build deps)
- `postinstall` (builds the React client into `server/public`)
- `[server] listening on http://...:8080`
- `[mongoose] connected`

Open `https://mern-birante-XXXXX.azurewebsites.net` — you should see the
app, and adding a user should persist to your Atlas cluster.

## Step 5 — Lock it down (post-checkpoint housekeeping)

1. **Rotate** the Atlas password (Security → Database Access → Edit).
2. **Update** the URI on Azure:

   ```bash
   az webapp config appsettings set -g rg-mern-birante -n mern-birante-XXXXX \
       --settings MONGO_URI="mongodb+srv://<new-password>..."
   ```

3. **Tighten** Atlas Network Access — remove `0.0.0.0/0`, add the
   App Service's outbound IPs:

   ```bash
   az webapp show -g rg-mern-birante -n mern-birante-XXXXX \
       --query outboundIpAddresses -o tsv
   ```

## API

| Method | Path                | Body                            | Returns          |
| ------ | ------------------- | ------------------------------- | ---------------- |
| GET    | `/api/health`       | —                               | `{ok: true}`     |
| GET    | `/api/users`        | —                               | `{users: [...]}` |
| POST   | `/api/users`        | `{name, email, role?}`          | `{user}` 201     |
| PUT    | `/api/users/:id`    | any subset of the fields above  | `{user}` updated |
| DELETE | `/api/users/:id`    | —                               | 204              |

Roles: `admin` / `member` / `viewer` (default `member`).

## Files

```
package.json                 -- root scripts (dev / start / postinstall / build)
.env.example                 -- template; real .env is gitignored
server/
  index.js                   -- Express server, Mongo connect, static React
  models/User.js             -- Mongoose schema
  routes/users.js            -- CRUD routes for /api/users
client/
  package.json               -- Vite + React
  vite.config.js             -- /api -> :3000 proxy in dev
  index.html                 -- Vite entry point
  src/
    main.jsx
    App.jsx                  -- one-page CRUD UI
    styles.css               -- responsive card layout
scripts/
  test-atlas.sh              -- boot the server against your Atlas cluster locally
  deploy-azure.sh            -- provision resources + configure + set up git deploy
```

## Verified locally

- `POST /api/users` × 2 → 201
- `GET /api/users` → 200 with 2 documents
- `PUT /api/users/:id` → 200, role updated, `updatedAt` bumped
- `DELETE /api/users/:id` → 204
- Adding a user via the browser UI persists to Mongo as expected
