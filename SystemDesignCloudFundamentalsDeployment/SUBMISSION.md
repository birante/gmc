# Checkpoint submission — Hosting a MERN App on Azure

## Live URL (to hand in)

`https://mern-birante-1868.azurewebsites.net`

Once the code is pushed (see below) this URL serves the MERN app.

## Azure resources currently provisioned

Verified via `az resource list -g rg-mern-birante-ne`:

| Resource                       | Type                       | Region        | SKU  |
| ------------------------------ | -------------------------- | ------------- | ---- |
| `rg-mern-birante-ne`           | Resource Group             | northeurope   | —    |
| `plan-mern-birante`            | App Service Plan (Linux)   | francecentral | B1   |
| `mern-birante-1868`            | Web App (Node 22 LTS)      | francecentral | B1   |

App settings on the Web App:

| Setting                          | Value                                                    |
| -------------------------------- | -------------------------------------------------------- |
| `NODE_ENV`                       | `production`                                             |
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `true` (Kudu runs `npm install` on push)                 |
| `WEBSITE_NODE_DEFAULT_VERSION`   | `~22`                                                    |
| `MONGO_URI`                      | *(set — points at the Atlas cluster)*                    |

**Cost note.** B1 tier is billed per minute (~$0.02/hour, ~$13/mo prorata).
`az group delete -n rg-mern-birante-ne --yes --no-wait` right after the
checkpoint is validated stops the meter.

## Two steps still to complete — you run these

### Step A — Open Atlas to Azure (30 s)

Because App Service outbound IPs aren't in the Atlas allow-list yet, the
running app can't reach the cluster. Temporarily allow everyone:

- https://cloud.mongodb.com → **Network Access** → **Add IP Address** →
  *Allow Access From Anywhere* (`0.0.0.0/0`) → *Confirm*.

Comment: *"temp for Azure deploy — remove after"*.

You'll restrict this back to the App Service's outbound IPs after the
demo — see the *Post-deploy tightening* section below.

### Step B — Push the code (2 min)

The App Service is ready to accept a Local Git push. Two commands to
set the deployment user, then five to push:

```bash
# Set a deployment user (one time, choose your own password)
az webapp deployment user set --user-name birantesy --password 'DeployPass2026!'

# Copy app/ to a fresh directory so we don't nest a git repo inside gmc/
cp -R /Users/macbook/Codes/GOMYCODE/gmc/SystemDesignCloudFundamentalsDeployment/app ~/mern-azure-deploy
cd ~/mern-azure-deploy

# Init, commit, add Azure remote, push
git init && git branch -M master
git add . && git commit -m "MERN app for Azure deployment"
git remote add azure "https://birantesy@mern-birante-1868.scm.azurewebsites.net/mern-birante-1868.git"
git push azure master
```

git will prompt for the deployment password (`DeployPass2026!` from the
first command). After that Kudu will run — visible via:

```bash
az webapp log tail -g rg-mern-birante-ne -n mern-birante-1868
```

You'll see, in order:

- `npm install` (installs Express, Mongoose, Vite build deps)
- `postinstall` runs → builds React into `server/public`
- `[server] listening on http://...:8080`
- `[mongoose] connected`

Then open `https://mern-birante-1868.azurewebsites.net` — the app should
load, and adding a user through the form should persist to Atlas.

## Alternative if git push refuses

If the deployment user or the push gets rejected, use ZIP deploy:

```bash
cd /Users/macbook/Codes/GOMYCODE/gmc/SystemDesignCloudFundamentalsDeployment/app
zip -r /tmp/mern-app.zip . -x "node_modules/*" ".env" ".git/*" "server/public/*" "client/dist/*" "client/node_modules/*"
az webapp deploy -g rg-mern-birante-ne -n mern-birante-1868 --src-path /tmp/mern-app.zip --type zip
```

## Post-deploy tightening (after the URL works)

- **Rotate the Atlas password**: Atlas → *Database Access* → *Edit password*.
- **Update `MONGO_URI` on Azure**:

  ```bash
  az webapp config appsettings set -g rg-mern-birante-ne -n mern-birante-1868 \
      --settings MONGO_URI="mongodb+srv://birantesy_db_user:<NEW>@freecluster0.830i12v.mongodb.net/mern_users?retryWrites=true&w=majority&appName=FreeCluster0"
  ```

- **Tighten Atlas Network Access** — remove `0.0.0.0/0`, add App Service outbound IPs:

  ```bash
  az webapp show -g rg-mern-birante-ne -n mern-birante-1868 --query outboundIpAddresses -o tsv
  ```

  Paste those IPs one by one in Atlas → *Network Access*, remove `0.0.0.0/0`.

- **Delete when done** (stops the B1 billing):

  ```bash
  az group delete -n rg-mern-birante-ne --yes --no-wait
  ```

## Code repo

The source lives at:

```
SystemDesignCloudFundamentalsDeployment/
├── README.md                -- index
├── SUBMISSION.md            -- (this file)
├── analysis.md              -- full deployment guide (references)
├── samples/                 -- reference config (env, package.json, GH workflow)
└── app/                     -- the deployable MERN app
    ├── package.json         -- start, dev, postinstall (builds React)
    ├── .env                 -- gitignored; contains MONGO_URI (rotate the password!)
    ├── .env.example         -- template
    ├── server/
    │   ├── index.js         -- Express + Mongoose + static React
    │   ├── models/User.js
    │   └── routes/users.js
    ├── client/              -- Vite + React CRUD UI
    └── scripts/
        ├── test-atlas.sh    -- verify local against Atlas
        └── deploy-azure.sh  -- provisions the App Service (already run — resources exist)
```

If you push this to GitHub, that repo is the second deliverable
(alongside the live URL).

## Summary — what to hand in

- **Live URL:** `https://mern-birante-1868.azurewebsites.net` (once
  Step B is done)
- **GitHub repo:** `https://github.com/<your-handle>/<repo>` (create if
  you want CI/CD via GitHub Actions — see `samples/github-workflow.yml`)
- **Screenshot:** open the URL, screenshot the app after adding a user
