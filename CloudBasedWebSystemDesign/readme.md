# VaxTrack

**Cloud-based vaccination scheduling, reminders and coverage monitoring for primary health clinics in West Africa.**

GoMyCode capstone: *Cloud-Based Web System Design* (assignment brief: [`readme.md`](readme.md)).

> **Live demo:** `https://vaxtrack.onrender.com` _(placeholder: replace it with your Render URL after deployment)_
> Demo accounts: `infirmier.yoff@vaxtrack.sn` / `Demo!2026` (clinician), `admin@vaxtrack.sn` / the `ADMIN_PASSWORD` you set (administrator).
> Public lookup: card `VX-DEMO-2026`, phone digits `4567`.

## The problem

Children in Senegal should receive about 18 vaccine doses over 6 or more visits before 15 months. Paper registers make it hard to see who is due or late, so children drop out of the schedule unnoticed. VaxTrack gives each clinic:

- **Child registration** with the national EPI schedule generated automatically (18 doses, stored as data, so it can be changed without a release)
- **Dose recording** (date, lot number, vaccinator) with conflict protection and undo
- **A daily worklist** of doses due in 7 days and overdue doses (defaulter tracing)
- **Grouped SMS reminders** in French, never repeated within 7 days (pluggable provider)
- **A dashboard** with coverage per dose against a 90% target, the Penta1-Penta3 dropout (WHO indicator) and a monthly trend
- **A public caregiver lookup** (card number + last 4 phone digits, minimal data returned)
- **Roles:** clinicians are isolated to their clinic; administrators manage clinics and users and see the whole district

## Stack

| Layer | Technology |
|---|---|
| Front-end | React 19, Vite 7, TypeScript, Tailwind CSS 4, React Router 7 |
| API | Node 22, Express 5, TypeScript, zod, JWT + bcrypt, helmet, express-rate-limit, pino, OpenAPI 3.1 + Swagger UI |
| Data | PostgreSQL 17, Prisma ORM (versioned migrations) |
| Tests | Vitest, Supertest (integration against real PostgreSQL), Testing Library |
| Delivery | GitHub Actions CI, Render Blueprint (`render.yaml`), Dockerfile, docker-compose |

## Repository layout

```
CloudBasedWebSystemDesign/
├── apps/
│   ├── api/                      # Express REST API
│   │   ├── prisma/               # schema.prisma + migrations
│   │   ├── src/
│   │   │   ├── config/env.ts     # validated environment (fail fast)
│   │   │   ├── domain/           # pure business rules (schedule, status, coverage)
│   │   │   ├── lib/              # logger, prisma, jwt, errors, dates
│   │   │   ├── middleware/       # auth, RBAC + clinic scoping, rate limits, errors
│   │   │   ├── modules/<feature>/  # routes -> controller -> service -> repository
│   │   │   ├── docs/openapi.ts   # API contract
│   │   │   ├── scripts/seed.ts   # idempotent seed (schedule, admin, demo data)
│   │   │   ├── container.ts      # composition root (dependency injection)
│   │   │   ├── app.ts            # HTTP pipeline
│   │   │   └── server.ts         # bootstrap + graceful shutdown
│   │   └── tests/{unit,integration}
│   └── web/                      # React SPA (pages, components, api client, tests)
├── docs/                         # REPORT, ARCHITECTURE, DEPLOYMENT, PRESENTATION
├── .github/workflows/ci.yml      # CI when this folder is a standalone repo
├── Dockerfile · docker-compose.yml · render.yaml
└── SUBMISSION.md
```

## Run locally

**Requirements:** Node 22 and PostgreSQL 15 or later (or Docker).

```bash
npm install
cp apps/api/.env.example apps/api/.env   # set DATABASE_URL and JWT_SECRET
npm run db:migrate                       # create the schema
npm run db:seed                          # EPI schedule + admin + demo data
npm run dev                              # API http://localhost:4000, web http://localhost:5173
```

With Docker only: `docker compose up --build`, then open http://localhost:4000.

API docs: http://localhost:4000/api/docs. Health check: http://localhost:4000/health.

## Quality checks

```bash
npm run lint          # ESLint (API + web)
npm run typecheck     # tsc on both apps
npm test              # API unit + integration (needs DATABASE_URL or TEST_DATABASE_URL) + web tests
npm run build         # production bundles
```

Latest local results: lint and typecheck clean. API: **53 tests passing** (38 unit + 15 integration on PostgreSQL 17), with 87.9% statement coverage. Web: **12 component tests passing**. Without a database, the integration suite is skipped and the unit tests still run.

## Deploy

One-click infrastructure-as-code on Render: **New -> Blueprint**, repo `birante/gmc`, path `CloudBasedWebSystemDesign/render.yaml`. Full guide (environment variables, migrations, custom domain, Vercel and Docker/Azure/GCP/AWS alternatives): [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Documentation

- [`docs/REPORT.md`](docs/REPORT.md): project report (research, design, deployment, about 3,100 words plus references)
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): Mermaid diagrams (context, containers, components, deployment, ER, sequence)
- [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md): step-by-step cloud deployment
- [`docs/PRESENTATION.md`](docs/PRESENTATION.md): 10-minute demo script
- [`SUBMISSION.md`](SUBMISSION.md): deliverables checklist

## Disclaimer

This is an educational prototype that uses synthetic data. The vaccination schedule must be validated against current Ministry of Health guidance before any real use. Processing real health data requires legal (CDP Senegal), ethical and security review.

## Author

Birante SY. MIT License.
