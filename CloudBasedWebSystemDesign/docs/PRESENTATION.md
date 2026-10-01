# VaxTrack - 10-minute presentation and demo script

**Format:** screen recording (slides plus live demo) of 9:30-10:00 minutes.
**Before you record:** open the public URL 2 minutes early so the free Render instance wakes up. Log out. Prepare three browser tabs: the public URL, `/api/docs`, and the GitHub Actions page. Zoom the browser to 125%.

| # | Time | Section | On screen |
|---|---|---|---|
| 1 | 0:00-0:45 | Hook and problem | Title slide, then problem slide |
| 2 | 0:45-1:45 | Evidence (literature) | 3 bullet slide with sources |
| 3 | 1:45-2:30 | Solution and scope | Feature slide |
| 4 | 2:30-3:45 | Architecture | ARCHITECTURE.md diagrams (container + components) |
| 5 | 3:45-7:30 | Live demo | Deployed app |
| 6 | 7:30-8:30 | Quality, security, CI/CD | GitHub Actions run, test output, Swagger |
| 7 | 8:30-9:30 | Results, limits, next steps | Results slide |
| 8 | 9:30-10:00 | Close | Thank-you slide with URL + repo |

---

## 1. Hook and problem (0:00-0:45)

**Slide:** "VaxTrack - never miss a vaccine dose", with name, GoMyCode capstone and date.

Talking points:
- "I'm Birante Sy. I work at Institut Pasteur de Dakar, where vaccines are part of daily life."
- "A child in Senegal should receive about 18 vaccine doses before 15 months, over 6 or more clinic visits."
- "Many clinics still track this in paper registers. When a child misses a visit, nobody notices until much later. The child then stays unprotected against measles, polio or pneumonia."
- "My question: can a small, low-cost cloud system help a nurse see who is due, who is late, and remind families automatically?"

## 2. Evidence (0:45-1:45)

**Slide:** three short bullets, each with its source.
- WHO/UNICEF estimates (WUENIC): worldwide, millions of children each year miss the first DTP dose ("zero-dose") or drop out before the third dose. Most of them live in Africa and Asia.
- The WHO *Immunization Agenda 2030* puts "leave no one behind" and the use of data to find under-immunised children at its core.
- Reviews of mobile phone reminders (Cochrane review on patient reminder/recall; randomised trials such as M-SIMU in Kenya) suggest that SMS reminders can improve timely vaccination in low- and middle-income settings.

Talking points:
- "Dropout between the first and third pentavalent dose is a classic WHO indicator of access problems. VaxTrack computes it automatically."
- "I do not claim SMS solves everything. The evidence is promising but varies with context, and I discuss this in the report."

## 3. Solution and scope (1:45-2:30)

**Slide:** four boxes.
1. **Register** a child, and the full national EPI schedule is generated from the date of birth.
2. **Record** each dose (date, lot number, vaccinator).
3. **Act**: a daily worklist of due and overdue children, plus grouped SMS reminders in French.
4. **Monitor**: coverage per dose, Penta1-Penta3 dropout and monthly trend. Parents check the schedule with a card number.

Talking points: "Two roles: clinicians see only their own clinic, administrators see the whole district. Parents get a minimal, privacy-preserving view."

## 4. Architecture (2:30-3:45)

**Show:** ARCHITECTURE.md, the *Containers* diagram, then the *API components* diagram.

Talking points:
- "One Node 22 service on Render serves the React SPA and the REST API. One managed PostgreSQL database. One URL, no CORS, and it fits the free tier."
- "Inside the API: layered feature modules. Routes, then controllers that validate with zod, then services with the business rules, then repositories with Prisma. Pure domain functions compute dose status and coverage. They are the most tested part."
- "Key decision: dose status is *computed*, never stored. 'Overdue' is always correct, with no nightly batch job to break."
- "Key decision: the vaccination schedule is *data* in the database, so the Ministry can add a vaccine without a new release."
- "Why PostgreSQL rather than MongoDB? The data is strongly relational (clinic, patient, dose, vaccine), and the dashboard is GROUP BY queries. Integrity and transactions matter for health records."

## 5. Live demo (3:45-7:30)

Follow this exact path (about 3 min 45 s):

1. **Public lookup (30 s).** On the login page, click *Check your child's schedule*. Enter `VX-DEMO-2026` and `4567`. Point out the first name and initial only, the next dose highlighted, and the colour-coded statuses. Enter `0000` to show that a wrong phone returns a generic error ("no enumeration").
2. **Login as a nurse (15 s).** `infirmier.yoff@vaxtrack.sn` / `Demo!2026`.
3. **Dashboard (45 s).** Show the KPI cards (children, doses in 30 days, due this week, overdue) and the dropout card with its WHO 10% threshold. Point to the coverage bars with the 90% target marker, and to the monthly trend.
4. **Register a child (45 s).** Go to *Patients -> Register child*. Enter "Moussa Fall", born about 6 weeks ago, guardian phone `+221 77 555 12 34`. After saving, show the generated card number and the 18 planned doses. The birth doses show as Overdue and the 6-week doses as Due.
5. **Record a dose (30 s).** Click *Record dose* on BCG and enter lot `BCG-2026-10`. The status turns green and the completion bar moves.
6. **Worklist and reminders (45 s).** Open *Worklist*, then the *Due in 7 days* and *Overdue* tabs. Click *Preview SMS reminders* to show one French message per child, grouped. Click *Send now*, which reports "N of N sent". Mention that the console provider logs the messages and that a real gateway plugs into one interface.
7. **Isolation (15 s).** Optional: log in as `infirmier.pikine@vaxtrack.sn`. Moussa is not visible, because each clinic sees only its own patients.
8. **Admin (15 s).** Log in as `admin@vaxtrack.sn`. Show the clinic filter on the dashboard and the Admin page (add a clinic or user, deactivate an account).

Backup plan: if the network fails, run `docker compose up` locally and show `http://localhost:4000`, or play a pre-recorded clip of the same flow.

## 6. Quality, security, CI/CD (7:30-8:30)

**Show:** the GitHub Actions run (green), then `/api/docs`.

Talking points:
- "Every push runs lint, type-check, unit tests, integration tests against a real PostgreSQL service container, the production build and a Docker build. Render deploys only from `main`."
- "Tests: unit tests for the domain rules and services with fakes, supertest integration tests for the real HTTP and database flow (registration, double-recording conflict, clinic isolation, reminders, public lookup), and React component tests with Vitest and Testing Library."
- "Security: bcrypt hashes, short-lived JWTs with roles, clinic scoping in one place, zod validation everywhere, helmet headers and CSP, strict rate limits on login and lookup, log redaction, and secrets only in environment variables (Render generates the JWT secret)."
- "Docs: OpenAPI 3.1 contract and Swagger UI, generated from the code base, here."

## 7. Results, limitations, next steps (8:30-9:30)

**Slide:** "What works / What's next".

- Results: a working public deployment, a full core workflow, 4-click deployment through the Blueprint, and an automated test suite (show the counts from the README).
- Limitations (be honest): demo data is synthetic; the SMS gateway is simulated; there is no offline mode yet, which matters for rural clinics; it has not been validated with real nurses; the free tier sleeps.
- Next: an offline-first PWA, a real SMS or USSD gateway (Orange or another local provider), DHIS2 export of aggregate indicators, French/Wolof interface, a pilot with one district and measurement of on-time Penta3 versus the paper baseline.

## 8. Close (9:30-10:00)

**Slide:** public URL, GitHub repo, contact.

"VaxTrack shows that with a modest, well-architected cloud stack, a clinic can know every morning which children need a vaccine. Thank you."

---

### Recording tips
- Use OBS Studio or QuickTime screen recording at 1080p. Record your voice with a headset.
- Rehearse once with a timer; the demo is the part that overruns.
- Upload to YouTube (unlisted) or Google Drive, and paste the link into `SUBMISSION.md`.
