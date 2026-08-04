# Express Routing Checkpoint

Small Express app with three routed pages, a shared nav bar, EJS templating, and a **working-hours middleware** that closes the site outside of Monday-to-Friday 09:00-17:00.

## Run

```bash
npm install
npm start                # http://localhost:3000
```

Requires Node.js **≥ 14**.

## Try it

- **Currently within working hours (Mon-Fri, 09-17)?** — every page loads normally.
- **Currently outside?** — every page returns **`503 Service Unavailable`** with the closed screen.

You can force either state without changing your system clock, via env vars:

```bash
# Force "open" — Wednesday, 10:00
TEST_DAY=3 TEST_HOUR=10 npm start

# Force "closed" — Saturday, any hour
TEST_DAY=6 TEST_HOUR=10 npm start

# Force "closed" — Wednesday but past close
TEST_DAY=3 TEST_HOUR=20 npm start
```

`TEST_DAY` uses JavaScript's `Date.getDay()` convention: **0 = Sunday, 1 = Monday, …, 6 = Saturday**.

## Routes

| Method | Path        | View          | Status (open) | Status (closed) |
| ------ | ----------- | ------------- | :-----------: | :-------------: |
| GET    | `/`         | `home.ejs`    | 200           | 503             |
| GET    | `/services` | `services.ejs`| 200           | 503             |
| GET    | `/contact`  | `contact.ejs` | 200           | 503             |
| any    | unknown     | `closed.ejs`  | 404           | 503             |

## Custom middleware — `middleware/workingHours.js`

```js
function workingHoursMiddleware({ nowProvider = () => new Date() } = {}) {
  return function checkWorkingHours(req, res, next) {
    if (isWithinWorkingHours(nowProvider())) return next();
    res.status(503).render("closed", { title: "We are closed", currentTime: nowProvider().toString() });
  };
}
```

- Mon-Fri check: `day >= 1 && day <= 5`.
- Hours check: `hour >= 9 && hour < 17` (closes AT 17:00 sharp).
- `nowProvider` is an injectable clock, so tests can substitute a fixed time.
- `TEST_DAY` / `TEST_HOUR` env vars override the real clock — no need to touch the system time to demo the closed state.

The middleware is mounted with `app.use(workingHoursMiddleware())` **before** the route handlers, so it gates every page in one line.

## File tree

```
app.js                              -- Express server, routes, view engine wiring
middleware/workingHours.js          -- custom middleware
public/styles.css                   -- CSS
views/
├── partials/{head,nav,footer}.ejs  -- shared markup
├── home.ejs
├── services.ejs
├── contact.ejs
└── closed.ejs                      -- shown when the working-hours check fails
```

## Requirements checklist

- [x] Express server with routes for `/`, `/services`, `/contact`.
- [x] Nav bar on every page (Home, Our Services, Contact us), with active-link highlighting.
- [x] Custom middleware verifies the request time (Mon-Fri 09-17).
- [x] Pages styled with CSS (responsive, cards / forms).
- [x] Template engine used (**EJS**, with partials to avoid duplication).
