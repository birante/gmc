# VaxTrack: A Cloud-Based Platform for Vaccination Scheduling, Reminders and Coverage Monitoring in West African Primary Health Clinics

**Author:** Birante SY
**Programme:** GoMyCode - Cloud-Based Web System Design (capstone)
**Date:** October 2026
**Public URL:** _to be added after deployment (see SUBMISSION.md)_
**Source code:** github.com/birante/gmc, folder `CloudBasedWebSystemDesign/`

---

## Abstract

Routine childhood immunisation is one of the most cost-effective public health interventions. Yet many children in sub-Saharan Africa start their vaccination series late, miss doses or drop out before completing it. In many primary health facilities, follow-up still depends on paper registers and on the memory of overloaded staff. This report presents VaxTrack, a cloud-based web system that lets clinics:

- register children and generate the national Expanded Programme on Immunization (EPI) schedule automatically;
- record administered doses;
- work from a daily list of due and overdue children;
- send grouped SMS reminders to caregivers;
- monitor coverage and dropout indicators.

Caregivers can check a child's schedule online. The system combines a React single-page application, a layered Express/TypeScript REST API and PostgreSQL. It is packaged as infrastructure-as-code for the Render cloud platform and as a portable Docker image. Every change goes through continuous integration with automated tests. The report covers the problem and the literature, requirements, architecture, technology choices, security, scalability, CI/CD, deployment, testing, results and limitations.

## 1. Problem statement and literature review

### 1.1 The problem

A child in Senegal is expected to receive about eighteen vaccine doses before fifteen months of age. These doses are spread over at least six visits: at birth, at 6, 10 and 14 weeks, and at 9 and 15 months. Each missed or delayed visit leaves the child exposed to diseases such as measles, pertussis, polio or pneumococcal pneumonia.

The information side is often the weak link. Paper registers are organised by date of visit rather than by child, so finding defaulters means scanning pages manually, which busy nurses rarely have time to do. Monthly district reports are compiled by hand, late and error-prone. Working in a public health institution in Dakar, I see that the gap is often less about vaccines or knowledge than about timely, actionable information at the point of care.

### 1.2 Global and regional context

The WHO/UNICEF Estimates of National Immunization Coverage (WUENIC) are the reference source on immunisation performance. Recent releases show that global coverage with three doses of diphtheria-tetanus-pertussis vaccine (DTP3) has stagnated at around 84-85% since the COVID-19 pandemic. Roughly 14 million children per year receive no DTP dose at all. These "zero-dose" children are concentrated largely in the African region (WHO & UNICEF, 2024; 2025). Senegal's reported national coverage is relatively high compared with many neighbours. However, WUENIC data and the Demographic and Health Surveys (ANSD & ICF, EDS series) show differences between regions and socio-economic groups, so national averages can hide pockets of under-immunised children.

The WHO *Immunization Agenda 2030* (IA2030) is built around "leaving no one behind". Its priorities include identifying zero-dose and under-immunised children and using timely, high-quality data for action at every level (WHO, 2020). The dropout rate between the first and third DTP-containing doses is a standard indicator of utilisation problems, and values above 10% are commonly treated as a warning sign. A tool that shows, child by child, who started but did not complete the series is aligned with these priorities.

### 1.3 Evidence on reminders and digital registries

**Reminder and recall.** A Cochrane review concluded that patient reminder and recall interventions (letters, calls, text messages) probably improve immunisation uptake, although most studies came from high-income countries (Jacobson Vann et al., 2018). For low- and middle-income countries, Oyo-Ita et al. (2016) found that information and reminders for caregivers can improve childhood immunisation coverage, with evidence of variable certainty. In rural Kenya, the M-SIMU cluster randomised trial reported better coverage and timeliness with SMS reminders, especially when they were combined with small incentives (Gibson et al., 2017). A randomised trial in Pakistan also reported improved uptake with text reminders (Kazi et al., 2018). The literature therefore supports SMS reminders as a low-cost component of a broader strategy, but not as a solution on its own. Effects depend on phone access, literacy, language and the reliability of services.

**Electronic immunisation registries (EIRs).** EIRs record data per individual instead of in aggregate tallies. The Pan American Health Organization published practical guidance for planning and implementing them (PAHO, 2017). In Tanzania and Zambia, the Better Immunization Data (BID) Initiative led by PATH introduced facility-level electronic registries. Its reported lessons stress both the value of child-level data for finding defaulters and the need to design for limited connectivity, training and data quality. National systems in the region increasingly rely on DHIS2 for aggregate reporting (University of Oslo), so a facility tool should complement that ecosystem, not replace it.

### 1.4 Design principles derived

1. **Child-level, schedule-aware records**, so that every planned, given and late dose is known.
2. **Action over reporting.** The nurse's main screen is a worklist of whom to vaccinate or call, and reminders are built in. Dashboards come second.
3. **Low cost and low friction.** Commodity cloud hosting, an ordinary browser and no installation, so a district can pilot it quickly.

## 2. Requirements

There are three actors:

- **Clinicians**: nurses attached to one clinic.
- **Administrators**: district or programme officers.
- **Caregivers**: not authenticated.

| ID | Functional requirement |
|---|---|
| F1 | Register a child. The system generates the full EPI schedule and a unique card number. |
| F2 | View a child's schedule with a computed status per dose: given, due within 7 days, overdue, upcoming. |
| F3 | Record a dose (date, lot, vaccinator) and undo mistakes. A dose cannot be recorded twice. |
| F4 | Daily worklist of doses due within 7 days and of overdue doses. |
| F5 | One SMS reminder per child for upcoming or recently missed doses, never repeated within 7 days. |
| F6 | Dashboard: children followed, doses given, due and overdue, coverage per dose, Penta1-Penta3 dropout, monthly trend. |
| F7 | Caregiver lookup with card number plus the last four digits of the registered phone. |
| F8 | Administrators manage clinics and users and can view every clinic. |

Non-functional requirements:

- **Security and privacy:** authentication, role-based access, strict isolation between clinics, data minimisation.
- **Availability:** a health probe and graceful shutdown.
- **Maintainability:** typed modular code, automated tests, CI and a documented API.
- **Portability and low cost:** environment-variable configuration and PaaS hosting.
- **Usability:** a responsive interface for laptops and tablets.

## 3. System architecture

Full diagrams (system context, containers, components, deployment, ER model and sequence) are in `docs/ARCHITECTURE.md`.

### 3.1 Overview

VaxTrack is a three-tier system:

- a React single-page application (SPA) compiled to static files;
- a stateless REST API;
- a managed PostgreSQL database.

In production, the API process also serves the compiled SPA. Users therefore see a single HTTPS origin: pages on `/` and the API under `/api`. This removes cross-origin configuration and fits within one free Render instance. The SPA can still be hosted separately on a CDN such as Vercel by setting an environment variable.

### 3.2 Back-end

The API is organised into feature modules (`auth`, `users`, `clinics`, `vaccines`, `patients`, `immunizations`, `dashboard`, `reminders`, `public`, `health`). Each module has the same layers:

- **Routes** declare URLs and apply authentication and role guards.
- **Controllers** validate input with zod schemas and map results to HTTP.
- **Services** hold business rules, for example "clinicians create patients only in their own clinic" or "a dose cannot predate birth".
- **Repositories** contain Prisma queries only.

Rules that need no input/output are pure functions in a `domain` folder: schedule generation, dose status, coverage, dropout and card numbers. A composition root (`container.ts`) injects repositories into services and services into controllers. This dependency injection lets unit tests use fakes and lets the SMS provider be swapped behind a `SmsNotifier` interface.

The HTTP pipeline applies structured logging (pino), security headers (helmet), a CORS allow-list, compression, a body size limit and rate limiting. A central error handler turns validation, domain and database errors into one consistent JSON format.

### 3.3 Data model

The data model has five entities: `Clinic`, `User`, `Patient`, `Vaccine` and `Immunization`. Two decisions matter most.

**The schedule is data.** Each `Vaccine` row is one dose of the EPI schedule, for example `PENTA-1` at 42 days. The seed follows the WHO-recommended structure as implemented in Senegal. Because the schedule is a table, the programme can introduce a vaccine without a software release. Earlier patients receive the missing doses automatically when their record is next opened.

**Status is derived, not stored.** Each planned dose is one `Immunization` row with a scheduled date and an optional administration date. Whether a dose is overdue depends only on those dates and on today, so the status is computed at read time. No nightly job can fail and leave statuses stale. A unique constraint on (patient, vaccine) makes recording a dose a conflict-safe update. It also reduces coverage to one `GROUP BY`: children old enough for the dose form the denominator, and those who received it form the numerator.

### 3.4 Front-end

The SPA offers:

- a public lookup page;
- a login page;
- dashboard, patient list, registration, patient detail and worklist views;
- an administration view.

A small data-fetching hook keeps state local to each page, and a React context holds authentication. Tailwind CSS provides a consistent, accessible design: labelled inputs, ARIA roles on progress bars and alerts, and colours that are always paired with text.

## 4. Technology choices and justification

| Layer | Choice | Justification | Alternatives |
|---|---|---|---|
| Language | TypeScript (strict), full stack | One language; compile-time checks catch errors where data mistakes have consequences | JavaScript, Python |
| API | Express 5 | Mature, minimal, rich security ecosystem; native async error handling | Fastify, NestJS |
| Database | PostgreSQL 17 | Strongly relational data, transactions, constraints, aggregation; managed on every cloud | MongoDB |
| ORM | Prisma | Typed client, versioned migrations, parameterised queries | Drizzle, raw SQL |
| Validation | zod | One schema gives runtime validation and static types | Joi |
| Auth | JWT + bcrypt | Stateless, so it scales horizontally; slow password hashing | Sessions + Redis |
| Front-end | React 19, Vite, Tailwind 4 | Widely known, fast builds, small static output | Angular, Vue |
| Tests | Vitest, Supertest, Testing Library | One fast runner for API and UI | Jest |
| Hosting | Render Blueprint + Docker | Infrastructure as code, free tier, managed PostgreSQL, automatic HTTPS; Docker keeps Azure/GCP/AWS open | Vercel only, raw VM |

MongoDB was rejected because the data (clinic, patient, dose, vaccine) is relational and integrity matters for health records. Serverless functions were rejected because a long-lived process with a connection pool suits a relational database better and avoids cold-start effects on every request.

## 5. Security and privacy

Security was treated as a requirement from the start. The measures below are organised by the relevant OWASP Top 10 categories.

- **Access control.** Role guards protect every authenticated route. A single scoping function pins clinicians to their clinic. Integration tests check that a nurse from another clinic receives 403.
- **Cryptography.** Passwords are hashed with bcrypt. Tokens are signed with a random 256-bit secret generated by Render and never committed. Traffic runs over HTTPS, with HSTS set by helmet.
- **Injection.** zod validates every input. Queries are parameterised through Prisma, including the single raw SQL query.
- **Authentication failures.** Login is limited to 20 attempts per 15 minutes. It returns the same message for unknown emails and wrong passwords, and runs a bcrypt comparison even for unknown emails so timing reveals nothing. Deactivated accounts cannot sign in.
- **Misconfiguration.** Configuration is validated at boot, and the service refuses to start with a weak secret. The `X-Powered-By` header is removed, a Content Security Policy is set, and CORS uses an explicit allow-list.
- **Logging.** Logs are structured JSON with request ids. Authorisation headers and passwords are redacted.

**Privacy by design.** The public lookup requires two factors held by the family and returns only the child's first name and initial, the clinic and the schedule. A wrong combination gives the same error as an unknown card, which prevents enumeration. A real deployment in Senegal would also require compliance with Law No. 2008-12 on personal data and a declaration to the Commission de Protection des Données Personnelles (CDP).

## 6. Scalability and performance

The API is stateless: tokens replace sessions and nothing is kept in memory between requests. Horizontal scaling therefore only means raising the instance count. On the database side:

- composite indexes support name search and the date-range queries behind worklists, reminders and dashboards;
- lists are paginated;
- coverage uses grouped counts in SQL;
- independent dashboard queries run in parallel.

As an order of magnitude, a district with 50 clinics and 10,000 births per year adds about 180,000 dose rows per year, which is modest for PostgreSQL. At national scale, the next steps would be:

- a connection pooler;
- read replicas or short-lived caching for dashboards;
- moving reminders to a scheduled background worker (a Render Cron Job) with a queue, so that requests never wait on an SMS gateway.

The modular structure allows such a worker to be extracted without rewriting the services.

## 7. Continuous integration and delivery

A GitHub Actions workflow runs on every push and pull request. It lives at the monorepo root, filtered to this folder, and an equivalent copy sits in the project folder. It runs these steps:

1. Install dependencies with `npm ci`.
2. Run ESLint and the TypeScript compiler on both applications.
3. Start a PostgreSQL 17 service container and apply the migrations.
4. Run the API unit and integration tests with coverage, then the React component tests.
5. Build the production bundles and the Docker image.

Render handles delivery. Automatic deploys from `main` are restricted by a build filter to this folder. Each deploy builds, applies pending migrations at start-up and only receives traffic once `/health`, which also checks the database, reports healthy. A failed check keeps the previous version online, and earlier deploys can be restored in one click.

## 8. Deployment

`render.yaml` declares a managed PostgreSQL database and a Node 22 web service in Frankfurt, the Render region closest to West Africa. The database URL is injected automatically and the JWT secret is generated. Only the administrator password has to be entered. An idempotent seed creates the schedule, the administrator and, for demonstrations, synthetic clinics and children. `docs/DEPLOYMENT.md` covers:

- the step-by-step procedure and the environment variables;
- migrations and rollback;
- custom domains;
- a Vercel option for the front-end;
- Docker commands for Azure Container Apps, Google Cloud Run and AWS App Runner.

## 9. Testing strategy

The tests follow the test pyramid.

- **Unit tests (Vitest)** cover the domain rules (status boundaries at 0, 7 and 8 days, schedule dates, coverage and dropout arithmetic, card numbers), access rules and JWT tampering. Service tests use fake repositories to check clinic assignment, code-collision retries, double recording, administration before birth, and reminder grouping and de-duplication. HTTP pipeline tests without a database check security headers, 401 responses, validation details, malformed JSON, CORS and 404s.
- **Integration tests (Supertest + real PostgreSQL)** cover login, registration with an 18-dose schedule, validation, clinic isolation, search, recording with conflict detection, worklists, dashboard figures, reminder sending and non-repetition, the minimal public lookup, user administration and deactivation, rescheduling after a corrected date of birth, and admin-only deletion.
- **Component tests (Testing Library + jsdom)** cover the status badge, the coverage bar (values, colours, accessibility), the caregiver lookup form and the dose table actions.

## 10. Results

All functional requirements F1-F8 are implemented. Locally, every check passes:

- **ESLint and TypeScript:** no errors.
- **API:** 53 tests (38 unit, 15 integration against PostgreSQL 17), with 87.9% statement coverage and 75.5% branch coverage (V8).
- **Front-end:** 12 component tests.
- **Production bundle:** about 91 kB of JavaScript and 5 kB of CSS (gzip).

The production build was also run end to end against a local PostgreSQL with demo data, and the main features were checked with HTTP requests:

- start-up migrations and the idempotent seed;
- the health check, login and role restrictions;
- registration, and recording a dose (with a 409 on repetition);
- worklists and the dashboard;
- reminders: four SMS messages generated and sent;
- the public lookup (success, and a generic 404 for a wrong phone);
- serving the SPA.

With 60 synthetic children, the dashboard computed Penta3 coverage and the Penta1-Penta3 dropout. These figures are synthetic and say nothing about real coverage. Deployment is fully scripted: after a push, creating the Render Blueprint and entering one password produce a public HTTPS URL.

## 11. Limitations

- **No field validation.** The system has not been tested with nurses or caregivers, so usability and workload effects are unknown.
- **Simulated SMS.** The adapter only logs messages. Cost, delivery, languages (Wolof, Pulaar) and literacy are not yet addressed.
- **Connectivity.** The system needs a connection, a key constraint highlighted by the BID experience.
- **Fixed-age schedule.** Minimum intervals, catch-up schedules and upper age limits (for example for rotavirus) are not modelled.
- **Free tier.** The Render free tier sleeps when idle and its free database is time-limited, so it is suitable for demonstration only.
- **Synthetic data only.** No real patient data may be used before legal, ethical and security reviews.

## 12. Future work

1. An offline-first progressive web app with background synchronisation.
2. A real SMS or USSD gateway with a local operator, and messages in local languages, including voice.
3. Catch-up and interval rules based on WHO recommendation tables, plus stock and lot management.
4. DHIS2 export of monthly aggregates to avoid double reporting.
5. Audit logs, multi-factor authentication for administrators and encryption of contact fields.
6. An ethically approved pilot in one district, measuring timely Penta3 and MR1 coverage and dropout against the paper baseline.

## 13. Conclusion

VaxTrack shows that a modest, well-structured cloud application can give primary health workers child-level, actionable vaccination information. Its design is grounded in the global immunisation agenda and in evidence on reminders and registries. The architecture favours simplicity: one stateless service, one relational database, computed statuses and a schedule stored as data. Security, testing and automated delivery are built in from the start. The remaining challenges are mostly contextual (connectivity, language, workflow and data governance), and the natural next step is to address them together with health workers.

## References

- Agence Nationale de la Statistique et de la Démographie (ANSD) [Sénégal] and ICF. *Enquête Démographique et de Santé (EDS / EDS-Continue)*, survey series. The DHS Program.
- Gibson, D. G., Ochieng, B., Kagucia, E. W., et al. (2017). Mobile phone-delivered reminders and incentives to improve childhood immunisation coverage and timeliness in Kenya (M-SIMU): a cluster randomised controlled trial. *The Lancet Global Health*, 5(4), e428-e438.
- Jacobson Vann, J. C., Jacobson, R. M., Coyne-Beasley, T., Asafu-Adjei, J. K., & Szilagyi, P. G. (2018). Patient reminder and recall interventions to improve immunization rates. *Cochrane Database of Systematic Reviews*, CD003941.
- Kazi, A. M., Ali, M., Zubair, K., et al. (2018). Effect of mobile phone text message reminders on routine immunization uptake in Pakistan: randomized controlled trial. *JMIR Public Health and Surveillance*, 4(1), e20.
- OWASP Foundation (2021). *OWASP Top 10: 2021*.
- Oyo-Ita, A., Wiysonge, C. S., Oringanje, C., Nwachukwu, C. E., Oduwole, O., & Meremikwu, M. M. (2016). Interventions for improving coverage of childhood immunisation in low- and middle-income countries. *Cochrane Database of Systematic Reviews*, CD008145.
- Pan American Health Organization (2017). *Electronic Immunization Registry: Practical Considerations for Planning, Development, Implementation and Evaluation*. Washington, D.C.: PAHO.
- PATH. *Better Immunization Data (BID) Initiative*: reports and lessons learned from Tanzania and Zambia.
- République du Sénégal (2008). *Loi n° 2008-12 du 25 janvier 2008 portant sur la protection des données à caractère personnel*.
- University of Oslo, HISP Centre. *DHIS2* documentation. dhis2.org.
- Wiggins, A. *The Twelve-Factor App*. 12factor.net.
- World Health Organization (2020). *Immunization Agenda 2030: A Global Strategy to Leave No One Behind*. Geneva: WHO.
- World Health Organization & UNICEF (2024, 2025). *WHO/UNICEF Estimates of National Immunization Coverage (WUENIC)*, 2023 and 2024 revisions. immunizationdata.who.int.
