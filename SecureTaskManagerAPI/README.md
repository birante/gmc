# Secure Task Manager API

Express REST API for managing personal tasks, secured with **JWT** (HTTP-only cookie) and optional **Google OAuth** via Passport.js. Includes standard hardening (helmet, xss-clean, mongo-sanitize, rate limits), centralised error handling, and owner-scoped access control.

## Run

```bash
cp .env.example .env       # (optional) configure secrets and Google OAuth
npm install
npm start                  # http://localhost:3000
npm test                   # 12 end-to-end smoke tests
```

Requires Node.js **≥ 18**.

## Storage note

Uses an **in-memory** store (`Map`-based) so the API runs out of the box with no external service. `express-mongo-sanitize` is still applied because it operates on `req.body`/`query`/`params` and is a good habit even without MongoDB present. The store surface (`findByEmail`, `create`, `findByOwner`, `deleteByIdForOwner`…) mirrors what a Mongoose model would expose — swapping to real MongoDB is a one-file change per model.

## API surface

| Method | Path                    | Auth       | Body                          | Success             |
| ------ | ----------------------- | ---------- | ----------------------------- | ------------------- |
| GET    | `/`                     | none       | —                             | 200 endpoint index  |
| POST   | `/auth/signup`          | none       | `{email, password}` (≥ 8 ch.) | 201 + auth cookie   |
| POST   | `/auth/login`           | none       | `{email, password}`           | 200 + auth cookie   |
| POST   | `/auth/logout`          | none       | —                             | 200, cookie cleared |
| GET    | `/auth/me`              | **JWT**    | —                             | 200 current user    |
| GET    | `/auth/google`          | none       | —                             | 302 → Google        |
| GET    | `/auth/google/callback` | (OAuth)    | —                             | 200 + auth cookie   |
| POST   | `/tasks`                | **JWT**    | `{title, description?}`       | 201 task            |
| GET    | `/tasks`                | **JWT**    | —                             | 200 own tasks       |
| DELETE | `/tasks/:id`            | **JWT**    | —                             | 204 (404 if not-owner) |

Errors are returned as `{ error: "message" }` with the appropriate 4xx/5xx status.

## Authentication

- **JWT is stored in an HTTP-only cookie** (`token`), `SameSite=Strict`, `Secure` in production.
- `verifyToken` middleware reads the cookie first, then falls back to `Authorization: Bearer …`.
- Passwords are bcrypt-hashed with a work factor of 12.
- Login runs bcrypt on a dummy hash when the email is unknown, to reduce user-enumeration via timing.

### Google OAuth

Register a project at [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials), copy the client ID and secret into `.env`, and set the authorised redirect URI to
`http://localhost:3000/auth/google/callback`. Then:

```
GET /auth/google           -> 302 to Google's consent screen
GET /auth/google/callback  -> 200 + auth cookie, JWT issued
```

If `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` are not set, the routes cleanly return **501 Not Implemented** — the rest of the API is unaffected.

## Security posture

| Concern              | Mitigation                                                         |
| -------------------- | ------------------------------------------------------------------ |
| XSS in request bodies| `xss-clean` escapes tags in every string value                     |
| NoSQL injection      | `express-mongo-sanitize` strips `$` / `.` from keys                |
| Response headers     | `helmet()` sets a strict set of security headers, disables `X-Powered-By` |
| Cookies              | `HttpOnly`, `SameSite=Strict`, `Secure` in production, 7-day maxAge |
| Brute-force on login | `express-rate-limit`: 10 attempts / 15 min / IP on `POST /auth/login` |
| Generic flood        | 300 requests / 15 min / IP everywhere else                         |
| Enumeration timing   | Bcrypt runs on a dummy hash on unknown-email login                 |
| Body size            | `express.json({ limit: "100kb" })` — refuses larger payloads       |
| Session state (OAuth)| `express-session` with `httpOnly`, `sameSite=lax` (needed for OAuth redirect back) |

## Error handling

- `utils/AppError.js` — operational errors (`new AppError("msg", 400)`).
- `utils/catchAsync.js` — wrapper: `catchAsync(fn)` forwards any async rejection to Express's error middleware.
- `middleware/errorHandler.js` — the last mount point:
  - Operational errors surface their message + status.
  - Non-operational errors log the stack, respond with generic `Internal server error` in production, full stack in dev.
- `notFound` middleware turns any unmatched route into a 404 `AppError`.

## Owner-scoped access control

Every task lookup is scoped by owner:

```js
// Task.findByIdForOwner returns null if the task exists but belongs to someone else,
// so the DELETE handler cannot leak or destroy another user's data.
async function deleteByIdForOwner(id, ownerId) { ... }
```

Verified by the smoke test suite: Alice creates a task, Bob's `DELETE` against Alice's task ID returns **404**, and Bob's `GET /tasks` returns an empty list.

## File tree

```
src/
├── app.js                    -- Express wiring, security middleware, routes
├── server.js                 -- bootstrap
├── config/passport.js        -- Google OAuth strategy (conditional)
├── controllers/
│   ├── authController.js
│   └── taskController.js
├── middleware/
│   ├── verifyToken.js
│   ├── errorHandler.js       -- notFound + centralised errorHandler
│   └── rateLimiters.js
├── models/
│   ├── User.js               -- in-memory user store
│   └── Task.js               -- in-memory, owner-scoped task store
├── routes/
│   ├── auth.js
│   └── tasks.js
└── utils/
    ├── AppError.js
    ├── catchAsync.js
    └── jwt.js
tests/
└── smoke.js                  -- 12 end-to-end tests
```

## Requirements checklist

- [x] JWT-based signup + login
- [x] JWT stored in an HTTP-only secure cookie (`SameSite=Strict`)
- [x] Google OAuth login via Passport.js (conditional, cleanly 501 if unconfigured)
- [x] `verifyToken` middleware protecting private routes
- [x] `POST /tasks`, `GET /tasks`, `DELETE /tasks/:id`, owner-only
- [x] `helmet`, `xss-clean`, `express-mongo-sanitize`, `express-rate-limit`
- [x] Reusable `AppError` class + centralised error middleware + `catchAsync` wrapper
- [x] 12 smoke tests, all green (`npm test`)
