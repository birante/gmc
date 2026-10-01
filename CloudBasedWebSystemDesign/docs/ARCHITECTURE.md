# VaxTrack - Architecture

This document describes the architecture of VaxTrack with [Mermaid](https://mermaid.js.org/) diagrams (GitHub renders them natively). It follows the C4 approach: system context, then containers and components, then deployment, data and a key runtime flow.

## 1. System context

```mermaid
flowchart LR
    nurse["Clinician / vaccinator<br/>(poste or centre de sante)"]
    admin["District / programme administrator"]
    parent["Parent or guardian"]
    vt(["VaxTrack<br/>cloud web system"])
    sms["SMS gateway<br/>(pluggable provider)"]
    dhis["National HMIS / DHIS2<br/>(future integration)"]

    nurse -- "registers children, records doses,<br/>works the due/overdue list" --> vt
    admin -- "manages clinics and users,<br/>monitors coverage and dropout" --> vt
    parent -- "looks up the schedule with<br/>card number + phone digits" --> vt
    vt -- "reminder SMS" --> sms --> parent
    vt -. "aggregate indicators (planned)" .-> dhis
```

## 2. Containers

```mermaid
flowchart TB
    subgraph Browser
        spa["React 19 SPA<br/>Vite + TypeScript + Tailwind"]
    end
    subgraph "Render web service (Node 22)"
        api["Express 5 REST API<br/>TypeScript, layered modules"]
        static["Static file server<br/>(built SPA, same origin)"]
    end
    db[("PostgreSQL 17<br/>Render managed")]
    sms["SMS provider adapter"]

    spa -- "HTTPS JSON /api/*<br/>Bearer JWT" --> api
    spa -- "HTTPS GET /, /assets/*" --> static
    api -- "Prisma ORM (TLS, pooled)" --> db
    api -- "SmsNotifier port" --> sms
```

A single service serves both the API and the compiled SPA. This removes CORS from the production path, needs one free Render instance, and gives one public URL. The SPA can also be hosted separately (Vercel) by setting `VITE_API_URL`; see DEPLOYMENT.md.

## 3. API components (layered, feature-modular)

```mermaid
flowchart LR
    subgraph HTTP["HTTP pipeline (app.ts)"]
        direction TB
        m1["pino-http<br/>request logging + id"] --> m2["helmet<br/>security headers / CSP"] --> m3["CORS allow-list"] --> m4["compression + JSON 100kb"] --> m5["rate limiter<br/>(global + sensitive)"]
    end

    subgraph Module["Feature module (e.g. patients/)"]
        direction TB
        r["*.routes.ts<br/>URL + auth/role guards"] --> c["*.controller.ts<br/>zod parsing, HTTP mapping"] --> s["*.service.ts<br/>business rules, clinic scoping"] --> repo["*.repository.ts<br/>Prisma queries only"]
    end

    domain["domain/<br/>pure functions:<br/>schedule, status, coverage,<br/>dropout, reference codes"]
    err["error-handler<br/>Zod / AppError / Prisma -> JSON"]
    container["container.ts<br/>composition root (DI)"]

    HTTP --> r
    s --> domain
    repo --> pg[("PostgreSQL")]
    c -. "throws" .-> err
    container -. "wires" .-> Module
```

Modules: `auth`, `users`, `clinics`, `vaccines`, `patients`, `immunizations`, `dashboard`, `reminders`, `public`, `health`.

Rules enforced by the structure:

- Routes never touch the database; repositories never contain business rules.
- Business rules that do not need I/O (dose status, schedule generation, coverage, dropout) live in `src/domain` and are unit-tested in isolation.
- Services receive repositories through their constructor, so unit tests inject fakes and integration tests use the real Prisma client.
- Every clinic-owned query goes through `resolveClinicScope` / `assertClinicAccess` (multi-tenant isolation in one place).

## 4. Deployment (Render)

```mermaid
flowchart TB
    dev["Developer laptop"] -- "git push" --> gh["GitHub<br/>birante/gmc"]
    gh -- "workflow: lint, typecheck,<br/>unit + integration tests (Postgres service),<br/>build, docker build" --> ci["GitHub Actions"]
    gh -- "auto-deploy on main<br/>(buildFilter: CloudBasedWebSystemDesign/**)" --> render

    subgraph render["Render - Frankfurt region"]
        direction TB
        build["Build: npm ci --include=dev<br/>npm run build (vite + tsc + prisma generate)"]
        start["Start: prisma migrate deploy<br/>-> node dist/server.js"]
        web["Web service 'vaxtrack'<br/>HTTPS, health check /health"]
        pg[("Managed PostgreSQL 'vaxtrack-db'")]
        build --> start --> web
        web -- "DATABASE_URL (internal network)" --> pg
    end

    users["Users (HTTPS)"] --> web
```

The same container image (`Dockerfile`) runs on Azure Container Apps, Google Cloud Run or AWS App Runner with only the environment variables changing.

## 5. Data model

```mermaid
erDiagram
    CLINIC ||--o{ USER : employs
    CLINIC ||--o{ PATIENT : follows
    PATIENT ||--o{ IMMUNIZATION : "has schedule"
    VACCINE ||--o{ IMMUNIZATION : "dose of"
    USER ||--o{ IMMUNIZATION : administered

    CLINIC {
        string id PK
        string code UK
        string name
        string region
        string district
    }
    USER {
        string id PK
        string email UK
        string name
        string passwordHash
        enum role "ADMIN | CLINICIAN"
        boolean active
        string clinicId FK
    }
    PATIENT {
        string id PK
        string referenceCode UK "printed on the card"
        string firstName
        string lastName
        enum sex
        date dateOfBirth
        string guardianName
        string guardianPhone
        string clinicId FK
    }
    VACCINE {
        string id PK
        string code UK "e.g. PENTA-1"
        string antigen
        int doseNumber
        int recommendedAgeDays
    }
    IMMUNIZATION {
        string id PK
        string patientId FK
        string vaccineId FK
        date scheduledDate
        date administeredDate "null = not given"
        string administeredById FK
        string lotNumber
        datetime reminderSentAt
    }
```

Design decisions:

- **Schedule as data.** The EPI schedule is stored in `Vaccine` rows, not hard-coded, so the programme can change it (for example when a new vaccine is introduced) without a release. Patients registered before a change are healed automatically the next time their record is opened.
- **Status is derived, never stored.** `OVERDUE / DUE / UPCOMING / ADMINISTERED` is calculated from `scheduledDate`, `administeredDate` and today's date. There is no nightly job that could fail and leave statuses stale.
- **One row per planned dose** (`@@unique([patientId, vaccineId])`) makes "record a dose" an idempotent update and makes coverage a cheap `GROUP BY vaccineId`.
- **Indexes** on `(clinicId, lastName)` for search and `(scheduledDate, administeredDate)` for worklists, reminders and dashboards.

## 6. Key flow - registering a child and sending reminders

```mermaid
sequenceDiagram
    autonumber
    actor N as Clinician
    participant W as React SPA
    participant A as Express API
    participant S as PatientsService
    participant D as domain/buildSchedule
    participant P as PostgreSQL
    participant R as RemindersService
    participant G as SMS gateway

    N->>W: Fill "Register child" form
    W->>A: POST /api/patients (Bearer JWT)
    A->>A: authenticate, zod validation
    A->>S: create(user, input)
    S->>S: resolveClinicScope (clinician -> own clinic)
    S->>P: SELECT vaccines (schedule)
    S->>D: buildSchedule(dateOfBirth, vaccines)
    D-->>S: 18 planned doses
    S->>P: INSERT patient + doses (one transaction)
    P-->>S: patient aggregate
    S-->>A: patient + computed statuses
    A-->>W: 201 Created + Location
    W-->>N: Card number VX-XXXX-XXXX and schedule

    Note over N,G: Later, from the worklist
    N->>W: "Preview SMS reminders" then "Send now"
    W->>A: POST /api/reminders/send
    A->>R: send(user)
    R->>P: pending doses in [today-30, today+3], not reminded in 7 days
    R->>R: group by child, build French SMS
    loop each child
        R->>G: send(phone, message)
        R->>P: UPDATE reminderSentAt
    end
    A-->>W: { candidates, sent, failed }
```

## 7. Cross-cutting concerns

| Concern | Implementation |
|---|---|
| Authentication | JWT (HS256, 8 h, issuer check), bcrypt password hashes (cost 10), constant-time path for unknown emails |
| Authorisation | Role guard (`ADMIN`, `CLINICIAN`) + clinic scoping in services |
| Validation | zod schemas on every body/query; 400 with field-level details |
| Security headers | helmet (CSP, HSTS, nosniff, frameguard), `x-powered-by` disabled |
| Abuse protection | Global rate limit 300 req / 15 min / IP; 20 req / 15 min on login and public lookup |
| Privacy | Public lookup needs card + phone digits, returns first name + initial only; logs redact auth headers and passwords |
| Observability | pino JSON logs with request ids, `/health` probe with DB check and commit SHA |
| Configuration | 12-factor: everything from environment variables, validated at boot (fail fast) |
| API contract | OpenAPI 3.1 at `/api/openapi.json`, Swagger UI at `/api/docs` |
