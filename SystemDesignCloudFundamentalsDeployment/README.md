# Hosting a MERN App on Microsoft Azure

Two-part deliverable:

- **A real MERN app** in [`app/`](./app) — Mongo + Express + React + Node,
  verified end-to-end locally, ready to deploy to Azure App Service.
- **A written guide** in [`analysis.md`](./analysis.md) — every step
  from a local dev machine to a live URL, with samples in
  [`samples/`](./samples).

Submission summary: [`SUBMISSION.md`](./SUBMISSION.md).

## Contents

```
SystemDesignCloudFundamentalsDeployment/
├── README.md              -- (this file)
├── SUBMISSION.md          -- what to hand in + post-deploy checklist
├── analysis.md            -- full walk-through of the deployment
├── samples/               -- reference config (env, package.json, GH workflow)
│   ├── .env.example
│   ├── package.json.snippet
│   ├── github-workflow.yml
│   └── azure-cli-setup.sh
└── app/                   -- the deployable MERN app
    ├── README.md
    ├── package.json
    ├── .env.example
    ├── server/
    │   ├── index.js
    │   ├── models/User.js
    │   └── routes/users.js
    ├── client/
    │   ├── package.json
    │   ├── vite.config.js
    │   ├── index.html
    │   └── src/{main.jsx,App.jsx,styles.css}
    └── scripts/
        ├── test-atlas.sh
        └── deploy-azure.sh
```

## Deploy in three commands

From the checkpoint root:

```bash
# 1) Verify locally against Atlas
cd app
export MONGO_URI="mongodb+srv://..."     # paste your Atlas URI here
./scripts/test-atlas.sh                   # opens http://localhost:3000

# 2) Provision + configure Azure (still with MONGO_URI in the env)
./scripts/deploy-azure.sh                 # runs `az login`, creates resources, prints a git URL

# 3) Push the code — Kudu builds React and starts Express
git init && git add . && git commit -m "MERN app"
git remote add azure <URL_PRINTED_BY_STEP_2>
git push azure main:master
```

See `SUBMISSION.md` for the checklist of what to submit and the
post-deployment security tightening steps (rotate Atlas password,
lock down Network Access).
