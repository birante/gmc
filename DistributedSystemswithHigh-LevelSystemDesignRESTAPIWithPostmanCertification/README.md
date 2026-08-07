# Users REST API — Express + Mongoose + Postman

Small REST API for a `Users` collection, following the checkpoint's exact folder layout:

```
config/.env
models/User.js
server.js
```

Four routes:

| Method | Path          | Purpose                       |
| ------ | ------------- | ----------------------------- |
| GET    | `/users`      | Return all users              |
| POST   | `/users`      | Add a new user                |
| PUT    | `/users/:id`  | Edit a user by id             |
| DELETE | `/users/:id`  | Remove a user by id           |

Testable via the included **Postman collection** or the `smoke.js` script.

## Setup

```bash
npm install                          # express, mongoose, dotenv
cp config/.env.example config/.env   # set MONGO_URI + PORT
```

`.env` fields:

```
PORT=5300
MONGO_URI="mongodb://127.0.0.1:27017/users_api"
```

*macOS note:* port 5000 is often taken by AirPlay Receiver — this checkpoint defaults to **5300** to avoid it. Change `PORT` if that conflicts too.

No MongoDB handy?

```bash
docker run -d --rm --name mongo -p 27017:27017 mongo:7
```

## Run

```bash
npm start                     # server listens on http://localhost:$PORT
```

Sample startup log:

```
Server running at http://localhost:5300
[mongoose] connected to mongodb://127.0.0.1:27017/users_api
```

## Test with Postman

Import [`postman_collection.json`](./postman_collection.json) — Postman → **Import** → drop the file. Four requests are pre-configured (`GET`, `POST`, `PUT`, `DELETE`), parameterised by two collection variables:

- `baseUrl` — defaults to `http://localhost:5000`; change to `http://localhost:5300` to match `.env` above.
- `userId` — paste the `_id` returned by the `POST` response into this variable so `PUT`/`DELETE` can reuse it.

Curl equivalents:

```bash
# POST
curl -sS -X POST http://localhost:5300/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Alice Diop","email":"alice@example.com","age":28}'

# GET
curl -sS http://localhost:5300/users

# PUT
curl -sS -X PUT http://localhost:5300/users/<id> \
  -H 'Content-Type: application/json' \
  -d '{"age":29}'

# DELETE
curl -sS -X DELETE http://localhost:5300/users/<id> -w '%{http_code}\n'
```

## Automated smoke test

`smoke.js` boots real HTTP requests against a running server and validates all four routes end-to-end:

```bash
npm start &          # in one terminal
PORT=5300 npm test   # in another
```

Sample output (from an actual run against MongoDB 7 in Docker):

```
--- users-rest-api smoke ---
POST   /users        -> 201 (id=6a763f2943fe821cdc4b0031)
GET    /users        -> 200 (1 users)
PUT    /users/:id    -> 200 (age now 29)
DELETE /users/:id    -> 204
verified deletion via GET

all four routes green.
```

## Schema

`models/User.js`:

| Field   | Type   | Constraints                                                    |
| ------- | ------ | -------------------------------------------------------------- |
| name    | String | required, trimmed                                              |
| email   | String | required, unique, lowercased, trimmed, regex-validated         |
| age     | Number | optional, `>= 0`                                               |
| createdAt / updatedAt | Date | Added automatically by `{ timestamps: true }`      |

## Error responses

| Situation                                | Status  | Body                                          |
| ---------------------------------------- | :-----: | --------------------------------------------- |
| Body fails a Mongoose validator          | 400     | `{ error: "<validator message>" }`            |
| Duplicate email (or other unique key)    | 409     | `{ error: "duplicate value: {\"email\":…}" }` |
| `:id` isn't a valid ObjectId             | 400     | `{ error: "invalid user id" }`                |
| No document with that id                 | 404     | `{ error: "user not found" }`                 |
| Unknown route                            | 404     | `{ error: "route not found" }`                |
| Anything unexpected                      | 500     | `{ error: "internal server error" }`          |

## Files

```
config/
  .env.example              -- template (real .env is gitignored)
models/
  User.js                   -- Mongoose schema + model
server.js                   -- Express server, connection, 4 routes
postman_collection.json     -- importable Postman collection
smoke.js                    -- automated end-to-end test
README.md
```

## Requirements checklist

- [x] `npm init` project structure
- [x] `mongoose` + `express` + `dotenv` installed
- [x] `.env` under `config/`, loaded by `dotenv`
- [x] Express server launched by `server.js`
- [x] Local (or Atlas) MongoDB connection via `mongoose.connect`
- [x] Folder layout: `config/.env`, `models/User.js`, `server.js`
- [x] `models/User.js` defines and exports a Mongoose schema
- [x] Four routes: `GET` all, `POST` new, `PUT` by id, `DELETE` by id
- [x] Every handler uses Mongoose methods and returns the result in the response
- [x] Postman collection provided
