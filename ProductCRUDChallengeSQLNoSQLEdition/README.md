# Product CRUD Challenge — SQL / NoSQL Edition

The same **Product** resource, CRUD'd twice from a single Express app:

- **`NoSQLcontroller.js`** — Mongoose against MongoDB.
- **`SQLcontroller.js`** — mysql2 against MySQL, with **parameterized statements** (no string interpolation of user input).

Both controllers expose the exact same request and response shape, so a client can hit either mount point interchangeably.

## Run

```bash
cp .env.example .env      # (optional) point at your MongoDB / MySQL
npm install
npm start                 # http://localhost:3000
npm test                  # smoke tests — skips any DB that is unreachable
```

Requires Node.js **≥ 18**.

## Bring up the databases

Fastest path — Docker one-liners on the standard ports:

```bash
docker run -d --name mongo -p 27017:27017 mongo:7
docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=secret \
              -e MYSQL_DATABASE=products -p 3306:3306 mysql:8
```

Or point the app at existing servers via `.env` (see `.env.example`). The app **boots even if one or both DBs are down** — the affected routes just return `503`.

## API surface (identical on both sides)

| Method | NoSQL path                | SQL path                 | Body                     | Success        |
| ------ | ------------------------- | ------------------------ | ------------------------ | -------------- |
| POST   | `/mongo/products`         | `/mysql/products`        | `{name, price, category?, inStock?}` | 201 + product  |
| GET    | `/mongo/products`         | `/mysql/products`        | —                        | 200 + list     |
| GET    | `/mongo/products/:id`     | `/mysql/products/:id`    | —                        | 200 or 404     |
| PUT    | `/mongo/products/:id`     | `/mysql/products/:id`    | any subset of fields     | 200 or 404     |
| DELETE | `/mongo/products/:id`     | `/mysql/products/:id`    | —                        | 204 or 404     |

Response product shape (both DBs):

```json
{
  "product": {
    "id":        "…",
    "name":      "Test Widget",
    "price":     9.99,
    "category":  "gadgets",
    "inStock":   true,
    "createdAt": "2026-08-04T14:22:00.000Z",
    "updatedAt": "2026-08-04T14:22:00.000Z"
  }
}
```

For MongoDB the id is a hex `ObjectId`; for MySQL it is an `AUTO_INCREMENT` integer — both come back at the `id` field on the JSON.

## Curl examples

```bash
# Create
curl -X POST http://localhost:3000/mysql/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Notebook","price":4.5,"category":"stationery"}'

# List
curl http://localhost:3000/mysql/products

# Get one
curl http://localhost:3000/mongo/products/6613…

# Update
curl -X PUT http://localhost:3000/mongo/products/6613… \
  -H 'Content-Type: application/json' \
  -d '{"price":5.0,"inStock":false}'

# Delete
curl -X DELETE http://localhost:3000/mysql/products/42
```

## Model comparison

| Field       | Mongoose schema                                        | MySQL DDL                                 |
| ----------- | ------------------------------------------------------ | ----------------------------------------- |
| `id`        | Auto `_id` ObjectId                                    | `INT AUTO_INCREMENT PRIMARY KEY`          |
| `name`      | `String`, `required: true`, `trim: true`               | `VARCHAR(255) NOT NULL`                   |
| `price`     | `Number`, `required: true`, `min: 0`                   | `DECIMAL(10, 2) NOT NULL`                 |
| `category`  | `String`, `default: null`                              | `VARCHAR(255) DEFAULT NULL`               |
| `inStock`   | `Boolean`, `default: true`                             | `BOOLEAN NOT NULL DEFAULT TRUE`           |
| timestamps  | `{ timestamps: true }` → `createdAt`, `updatedAt`      | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`, `TIMESTAMP … ON UPDATE`. |

The SQL controller normalises `in_stock` (`0`/`1`) back to a real `boolean` and coerces `DECIMAL` (returned as a string by mysql2) to a `Number` before responding, so the JSON shape stays identical.

## Security note — parameterized queries

Every value the SQL controller sends to MySQL goes through a placeholder:

```js
await pool.execute("INSERT INTO products (name, price, category, in_stock) VALUES (?, ?, ?, ?)",
                   [name, price, category, inStock]);
await pool.execute("UPDATE products SET name = ? WHERE id = ?", [name, id]);
await pool.execute("DELETE FROM products WHERE id = ?", [id]);
```

The only place the update handler interpolates strings into SQL is the column-name list — and that list is built from a whitelist (`{ name, price, category, inStock }`), never from `req.body` keys directly. **No user-controlled string is ever concatenated into a query.**

## Files

```
src/
├── app.js
├── server.js
├── db/
│   ├── mongoConnect.js          -- mongoose.connect (lazy, non-fatal)
│   └── mysqlPool.js             -- mysql2 pool + init.sql bootstrap
├── models/Product.js            -- Mongoose schema
├── sql/init.sql                 -- MySQL DDL
├── controllers/
│   ├── NoSQLcontroller.js       -- Mongoose CRUD
│   └── SQLcontroller.js         -- mysql2 CRUD (parameterized)
└── routes/
    ├── nosql.js                 -- mounted at /mongo
    └── sql.js                   -- mounted at /mysql
tests/
└── smoke.js                     -- boots the app, runs CRUD against any DB it can reach
```

## Requirements checklist

- [x] Mongoose schema + equivalent SQL table with matching fields.
- [x] Auto-generated `id` on both sides.
- [x] `name` required, `price` required, `category` optional, `inStock` default `true`.
- [x] Two controllers with complete CRUD each.
- [x] SQL controller uses parameterized statements throughout.
- [x] Both mounted under one Express app for side-by-side comparison.
