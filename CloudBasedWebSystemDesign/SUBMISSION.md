# Submission - Cloud-Based Web System Design (GoMyCode capstone)

**Student:** Birante SY
**Project:** VaxTrack - vaccination scheduling, reminders and coverage monitoring (health, West Africa)

## Deliverables

| Requirement (from `readme.md`) | Deliverable | Status |
|---|---|---|
| Real-world problem + short literature review | `docs/REPORT.md` sections 1-2 | Done |
| Full architecture, diagrams, justified technology choices | `docs/ARCHITECTURE.md` (6 Mermaid diagrams), `docs/REPORT.md` sections 3-4 | Done |
| Clean, modular, scalable implementation | `apps/api` (layered feature modules), `apps/web` | Done |
| Continuous integration and testing | `.github/workflows/cloud-web-system-ci.yml` (monorepo root), `.github/workflows/ci.yml`; 53 API tests + 12 web tests | Done (runs after push) |
| Cloud deployment tooling | `render.yaml` (Blueprint), `Dockerfile`, `docker-compose.yml`, `docs/DEPLOYMENT.md` | Done |
| Public link | **https://__________.onrender.com** | **To do: deploy** |
| Professional report (2,500-3,500 words) | `docs/REPORT.md`: 3,397 words with references, 3,109 without (code blocks excluded) | Done |
| 10-minute presentation / demo | Script: `docs/PRESENTATION.md`. Video: **link: __________** | **To do: record** |

## What you still have to do

### 1. Push the code (2 min)
```bash
cd /Users/macbook/Codes/GOMYCODE/gmc
git add CloudBasedWebSystemDesign .github/workflows/cloud-web-system-ci.yml
git commit -m "Add VaxTrack cloud-based web system (capstone)"
git push origin main
```
Then open GitHub, go to **Actions**, and check that the workflow "VaxTrack CI (CloudBasedWebSystemDesign)" passes.

### 2. Deploy on Render (5 min)
1. https://dashboard.render.com: **New + -> Blueprint** and connect `birante/gmc`.
2. **Blueprint Path:** `CloudBasedWebSystemDesign/render.yaml`.
3. Enter a strong `ADMIN_PASSWORD` when prompted, then click **Apply**.
4. Wait for the database and the web service to show *Live* (the first build takes about 3-5 min).
5. If Render gave a URL other than `https://vaxtrack.onrender.com` (the name was taken), update `CORS_ORIGINS` in the service environment. This is optional, because same-origin calls do not need it.
6. Check: `curl https://<your-url>/health` returns `{"status":"ok","database":"up",...}`.
7. Paste the URL into this file (table above), into `README.md` ("Live demo") and into `docs/REPORT.md` (header).

### 3. Record the 10-minute video (30-45 min)
- Follow `docs/PRESENTATION.md` (timed sections and the exact demo path).
- Open the site 2 minutes before recording, because the free instance sleeps after inactivity.
- Upload it unlisted to YouTube or Google Drive and paste the link above.

### 4. Submit on the GoMyCode platform
- GitHub link: `https://github.com/birante/gmc/tree/main/CloudBasedWebSystemDesign`
- Public URL (Render)
- Report: link to `docs/REPORT.md` on GitHub (or export it to PDF with VS Code "Markdown PDF" or `pandoc docs/REPORT.md -o REPORT.pdf`)
- Video link

## Notes
- Demo credentials: clinician `infirmier.yoff@vaxtrack.sn` / `Demo!2026`; admin `admin@vaxtrack.sn` / your `ADMIN_PASSWORD`; public lookup `VX-DEMO-2026` + `4567`.
- For a real deployment, set `SEED_DEMO_DATA=false`.
- `npm audit` reports one remaining advisory, in `deepmerge-ts`, a dependency of the Prisma 6 CLI/config loader. It is not reachable from the request path. Upgrading to Prisma 7 in a future iteration resolves it.
