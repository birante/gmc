# To-Do RESTful API — Node.js core modules only

CRUD REST API for managing to-do tasks, built with **only Node.js core modules** (`http`, `url`, `crypto`, `buffer`). No Express, no third-party middleware, no database — todos live in an in-memory array.

## Run

```bash
npm start        # starts the server on http://127.0.0.1:3000
npm test         # 13 end-to-end tests using node:http against the real server
```

Requires Node.js **≥ 18** (uses `crypto.randomUUID()` and ES modules).

## Project structure

```
src/
├── server.js    -- HTTP server, delegates to router
├── router.js    -- method + path dispatch, per-endpoint validation
├── store.js     -- in-memory todo array + CRUD helpers
└── http.js      -- readJsonBody, sendJson, sendError, sendNoContent

tests/
└── smoke.js     -- boots the server on port 0 and hits every route
```

## Resource

Every todo has this shape:

```json
{
  "id":        "1803ca8a-e4c4-43ee-a697-7716d9c35608",
  "title":     "Buy milk",
  "completed": false
}
```

- `id` — server-generated UUID, immutable.
- `title` — non-empty string, required on create, optional (but must remain non-empty) on update.
- `completed` — boolean, defaults to `false`.

## Endpoints

| Method | Path            | Body            | Success                     | Errors                                 |
| :----- | :-------------- | :-------------- | :-------------------------- | :------------------------------------- |
| GET    | `/`             | —               | 200 — API index             |                                        |
| GET    | `/todos`        | —               | 200 — array of todos        |                                        |
| POST   | `/todos`        | `{title, completed?}` | 201 — created todo    | 400 (missing/invalid fields, bad JSON) |
| GET    | `/todos/:id`    | —               | 200 — the todo              | 404 (unknown id)                       |
| PATCH  | `/todos/:id`    | `{title?, completed?}` | 200 — updated todo   | 400, 404                               |
| PUT    | `/todos/:id`    | *(alias of PATCH)* | 200                      | 400, 404                               |
| DELETE | `/todos/:id`    | —               | 204 — no content            | 404 (unknown id)                       |
| any    | anything else   | —               |                             | 404 (unknown route), 405 (wrong method)|

Error responses share a common shape:

```json
{ "error": "Field 'title' is required and must be a non-empty string" }
```

The server also rejects payloads over 100 KB with `413 Payload Too Large`.

## Examples

```bash
# create
curl -sS -X POST http://127.0.0.1:3000/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Buy milk"}'
# -> 201 Created
# -> {"id":"…","title":"Buy milk","completed":false}

# list
curl -sS http://127.0.0.1:3000/todos
# -> 200 OK, [ { ... } ]

# mark completed
curl -sS -X PATCH http://127.0.0.1:3000/todos/<id> \
  -H 'Content-Type: application/json' \
  -d '{"completed":true}'
# -> 200 OK, { "id":"…", "title":"Buy milk", "completed":true }

# delete
curl -sS -X DELETE http://127.0.0.1:3000/todos/<id> -w '%{http_code}\n'
# -> 204
```

## Status-code cheat sheet

| Code | Used for                                                          |
| :--: | ----------------------------------------------------------------- |
| 200  | Successful read / update                                          |
| 201  | Resource created (`POST /todos`)                                  |
| 204  | Successful delete — no body                                       |
| 400  | Malformed JSON or invalid field types / empty required fields     |
| 404  | Unknown route or unknown resource id                              |
| 405  | Known path but the method isn't supported on it                   |
| 413  | Request body larger than 100 KB                                   |
| 500  | Unexpected server error (guard rail — should not happen)          |

## Design notes

- **Validation is at the boundary.** The router validates request shape and delegates to `store.js`, which trusts its inputs. This keeps the store tiny and the error messages meaningful.
- **UUIDs, not counters.** IDs come from `crypto.randomUUID()` — safe from guessable enumeration and free from a shared counter that would need locking in a real concurrent server.
- **The store exposes `_reset()`** so tests can wipe state between cases without a global variable escape hatch.
- **`createApp()` returns the server** without listening, so tests can boot on port 0 and shut down cleanly (`server.close()`).
- **No third-party deps** — the whole thing runs on a stock Node install.
