# Hosting a MERN App on Microsoft Azure

Deployment walk-through — every step from a working local MERN app to a
live production URL on Azure App Service, with MongoDB Atlas providing
the database.

---

## 1. Prerequisites

- A **MERN** app that already runs locally (`M`ongoDB, `E`xpress,
  `R`eact, `N`ode).
- A **GitHub** account (nice to have — enables the GitHub-Actions
  deployment path).
- A **Microsoft Azure** account. Sign up at
  [portal.azure.com](https://portal.azure.com); the free tier includes
  ~$200 of credit for 30 days and a Free (F1) App Service plan.
- A **MongoDB Atlas** account
  ([mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)).
  Atlas offers a free M0 shared cluster in Azure regions.

---

## 2. MongoDB Atlas setup

Azure does **not** offer MongoDB natively (it offers Cosmos DB, which
has a Mongo-API layer — usable, but different pricing and quirks). The
standard pattern is Atlas.

### 2.1 Create the cluster

1. In Atlas → *Build a Database* → **M0** (free) or **M10** for a small
   paid cluster.
2. Cloud provider: **Microsoft Azure**. Region: pick the **same Azure
   region** you'll deploy the App Service in (e.g. `West Europe` /
   `East US`) so cross-network latency stays under 5 ms.
3. Cluster name: something like `mern-prod`.

### 2.2 Database user

*Security → Database Access → Add new database user.*

- **Password authentication**.
- **Read and write to any database** (or scoped to a specific DB).
- Store the password in a **secrets manager** — you'll need it once for
  the Azure config; do not commit it.

### 2.3 Network access

*Security → Network Access → Add IP address.*

Options, from least to most restrictive:

| Option                                        | When to use                    |
| --------------------------------------------- | ------------------------------ |
| `0.0.0.0/0` (allow all)                       | Never in production            |
| Azure App Service outbound IP range           | Simple, mostly right           |
| **Private endpoint / VNet peering**           | Recommended for anything real  |

Azure App Service has **many** outbound IPs (they change as instances
scale). The cleanest solution is a **Private Endpoint** from Atlas into
your Azure VNet — the DB is unreachable from the public internet at all.

### 2.4 Grab the connection string

*Databases → Connect → Drivers → Node.js.* Copy the URI, which looks
like:

```
mongodb+srv://<user>:<password>@mern-prod.abcd.mongodb.net/mydb?retryWrites=true&w=majority
```

You'll set this as an environment variable in Azure — never bake it
into the code.

---

## 3. Prepare the MERN app for deployment

### 3.1 Everything sensitive comes from env vars

```js
// server/index.js
require("dotenv").config();
const mongoose = require("mongoose");
mongoose.connect(process.env.MONGO_URI);
const app = require("express")();
// …
const PORT = process.env.PORT || 3000;  // Azure sets PORT for you
app.listen(PORT);
```

Never hard-code the URI. Ship a `.env.example` (in this repo:
`samples/.env.example`) so teammates know what to set.

### 3.2 Build the React frontend for production

From `client/`:

```bash
npm ci
npm run build     # -> client/build/
```

### 3.3 Single-server pattern (Express serves the built React)

Copy the built assets into the backend so a single Node process
answers everything — this makes deployment on App Service dramatically
simpler than running two services with a reverse proxy.

```js
// server/index.js
const path = require("path");
const express = require("express");
const app = express();

// API routes …
app.use("/api", apiRouter);

// Static React
app.use(express.static(path.join(__dirname, "public")));
app.get("*", (req, res) =>
  res.sendFile(path.join(__dirname, "public", "index.html"))
);
```

Automate the copy in `package.json`:

```json
{
  "scripts": {
    "build":     "cd client && npm ci && npm run build && rm -rf ../server/public && cp -R build ../server/public",
    "start":     "node server/index.js",
    "postinstall": "npm run build"
  },
  "engines": { "node": ">=18" }
}
```

`postinstall` matters: Azure runs `npm install` after upload, which
triggers `postinstall`, which builds React. That saves you from
committing built assets.

### 3.4 Listen on the port Azure sets

Azure App Service injects `process.env.PORT` and expects the app to
listen on it. Don't hard-code `3000` in production code.

---

## 4. Create the Azure App Service

### 4.1 Via the Portal (walk-through)

1. Portal home → *Create a resource* → *Web* → **Web App**.
2. Fill in the form:
   - **Subscription** and **Resource group** (create a new one, e.g.
     `rg-mern-prod`).
   - **Name** — must be globally unique; becomes
     `<name>.azurewebsites.net`.
   - **Publish**: `Code`.
   - **Runtime stack**: `Node 18 LTS` (or newer).
   - **Operating System**: `Linux` — cheaper and simpler for Node than
     Windows App Service.
   - **Region**: same as your Atlas cluster.
   - **Pricing plan**: `F1 Free` for demos, `B1 Basic` (~$13/mo) for
     small workloads, `P1v3` for production.
3. Review + Create.

### 4.2 Via the Azure CLI (same steps, five commands)

See `samples/azure-cli-setup.sh` for a runnable version. The essence is:

```bash
az group create -n rg-mern-prod -l westeurope

az appservice plan create -n plan-mern-prod -g rg-mern-prod \
    --is-linux --sku B1

az webapp create -g rg-mern-prod -p plan-mern-prod \
    -n my-mern-app --runtime "NODE:18-lts"

# App settings (repeated per env var)
az webapp config appsettings set -g rg-mern-prod -n my-mern-app --settings \
    MONGO_URI="mongodb+srv://…" JWT_SECRET="…" NODE_ENV=production

# Deployment source
az webapp deployment source config-local-git -g rg-mern-prod -n my-mern-app
```

The CLI path is reproducible, versionable, and 30× faster than
click-driving the Portal for the fifth environment.

---

## 5. Deploy the app

Three ways in, all equivalent for App Service:

### 5.1 Local Git (portal-recommended)

1. In the App Service → *Deployment Center* → source **Local Git** →
   *Save*.
2. Set a deployment user *once*: Deployment Center → *FTPS credentials*
   → *User scope*.
3. Portal shows a Git URL like
   `https://<user>@my-mern-app.scm.azurewebsites.net/my-mern-app.git`.
4. Locally:

   ```bash
   git remote add azure https://<user>@my-mern-app.scm.azurewebsites.net/my-mern-app.git
   git push azure main
   ```

5. Kudu (the App Service build system) runs `npm install`, which triggers
   `postinstall → npm run build`, which builds React into `server/public`.
6. App Service restarts and serves the new build.

### 5.2 GitHub Actions (recommended for real projects)

*Deployment Center → source **GitHub** → sign in → pick repo + branch.*
Azure will commit a workflow file into `.github/workflows/`. A minimal
version is included at `samples/github-workflow.yml`. Highlights:

- CI installs deps, runs tests, builds the app.
- Azure/Login step authenticates using a **publish profile** stored as
  a GitHub secret (`AZUREAPPSERVICE_PUBLISHPROFILE`).
- `azure/webapps-deploy@v3` uploads the artefact.

This gives you tests-gate-deploy, per-branch preview slots, and a full
audit trail.

### 5.3 ZIP deploy / OneDeploy

For a one-off:

```bash
zip -r app.zip . -x "node_modules/*" ".git/*"
az webapp deploy -g rg-mern-prod -n my-mern-app --src-path app.zip
```

Useful for quick tests and CI systems that don't have a native Azure
integration.

---

## 6. Configure environment variables

*App Service → Settings → **Environment variables** (or Configuration).*

Add every value from `.env`:

| Setting              | Example                                                    |
| -------------------- | ---------------------------------------------------------- |
| `MONGO_URI`          | `mongodb+srv://user:***@mern-prod.…/mydb`                  |
| `JWT_SECRET`         | 32+ random bytes                                           |
| `NODE_ENV`           | `production`                                               |
| `WEBSITES_PORT`      | Omit — Azure sets `PORT` automatically                     |
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `true` (forces Kudu to run `npm install`)       |

Every change restarts the app. **App Service secrets are encrypted at
rest**, unlike `.env` files committed to a repo.

---

## 7. Test the deployed app

- Open `https://<name>.azurewebsites.net`.
- **Logs**: App Service → *Log stream* — a live tail of `stdout`,
  invaluable when the first request 500s. Also available via
  `az webapp log tail`.
- **Application Insights** — one-click enable during App Service
  creation. Traces per request, dependency latency (including Mongo),
  error grouping.
- **Health check** — App Service can ping a health endpoint (e.g.
  `/api/health`) every N seconds and auto-restart on failure.

---

## 8. Cost picks

| Tier                | Price (rough) | Good for                              |
| ------------------- | ------------: | ------------------------------------- |
| **F1 Free**         | 0             | Demo only; 60 min CPU/day; no custom domains |
| **B1 Basic**        | ~$13/mo       | Personal projects, prototypes         |
| **S1 Standard**     | ~$70/mo       | Small production; autoscaling; slots  |
| **P1v3 Premium v3**| ~$110/mo      | Production; better CPU + memory       |
| **I1 Isolated**     | $$$           | Regulated workloads on private VNet   |

Atlas M0 is free but shared and rate-limited. **M10 (~$60/mo) is the
minimum for anything you plan to keep running**. Point the App Service
and the Atlas cluster at the **same region** to avoid inter-region
egress.

---

## 9. Common pitfalls

- **Building on Kudu times out.** Client builds can hit the App Service
  build timeout on tiny plans. Fix: build in CI (GitHub Actions), then
  deploy the built artefact — no `npm run build` on Kudu.
- **`PORT` hard-coded.** App silently listens on `3000` while Azure
  expects the app on `process.env.PORT`. Result: `Application Error`.
- **Atlas IP allow-list too tight.** App Service outbound IPs change
  after scale-out. Use *Private Endpoint* or the full published App
  Service outbound-IP list.
- **CORS.** If backend and static assets are served from the same
  origin (single-server pattern above), no CORS needed. If they aren't,
  configure `cors` middleware carefully.
- **Cold starts on F1.** The free tier sleeps after 20 minutes idle;
  first request after that can take 20 s. B1+ is *Always On*.
- **Case-sensitive filesystem.** Local macOS / Windows dev is case
  insensitive; Linux App Service is not. `require("./Component")` for a
  file named `component.js` breaks in prod. Match the case in every
  import.
- **Secrets in Git.** `.env` must be gitignored. Set them in App
  Service configuration, not the repo.
- **Static React caching.** After a deploy, the browser can hold onto
  an old `index.html`. Serve it with `Cache-Control: no-cache` and let
  the hashed asset files be cached forever.
- **Mongo connection storms on restart.** App Service restarts open
  many connections at once. Use a connection pool (`mongoose` default)
  and cap it (`maxPoolSize`) so Atlas doesn't reject.
- **Node version mismatch.** Kudu reads `engines.node` from
  `package.json`. If it's missing or wildcard, App Service may pick a
  different LTS than you tested against.

---

## 10. What "done" looks like

- `https://<name>.azurewebsites.net` returns the React app.
- The React app calls `/api/*` on the same origin and Mongo Atlas
  returns real data.
- Deploying a change is `git push azure main` (or a merge to `main`
  through GitHub Actions).
- Rotating a secret is a config change in Azure — no redeploy needed
  beyond a restart.
- Logs stream live and Application Insights groups 5xx by endpoint.

That's the deliverable.
