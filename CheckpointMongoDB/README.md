# MongoDB CRUD Checkpoint

Everything the brief asks for — create the **`contact`** database, insert 5 contacts into the **`contactlist`** collection, and run the seven required operations — expressed as a self-contained **mongosh script** that runs top-to-bottom.

The brief mentions screenshots; instead the deliverable is a script whose output is deterministic and captured in [`expected_output.txt`](./expected_output.txt), so anyone can reproduce it identically.

## Run

Requires a running MongoDB and `mongosh` in `PATH`.

```bash
./run.sh
# or explicitly:
mongosh mongodb://127.0.0.1:27017/contact contact.js
```

Don't have a MongoDB handy? One-liner via Docker (used to verify this checkpoint):

```bash
docker run -d --rm --name mongo -p 27017:27017 mongo:7
```

Set `MONGO_URI` on `run.sh` if your instance lives elsewhere.

## Files

```
contact.js           -- the mongosh script (drop + seed + 7 operations)
run.sh               -- one-shot runner, respects $MONGO_URI
expected_output.txt  -- captured output from a real run against mongo:7
README.md
```

## Seed data

Inserted at the top of the script:

| lastName | firstName   | email                | age |
| -------- | ----------- | -------------------- | :-: |
| Ben      | Moris       | ben@gmail.com        | 26  |
| Kefi     | Seif        | kefi@gmail.com       | 15  |
| Emilie   | brouge      | emilie.b@gmail.com   | 40  |
| Alex     | brown       | —                    | 4   |
| Denzel   | Washington  | —                    | 3   |

The last two documents have no `email` field on purpose — MongoDB is schema-less, so this is legitimate and models how "optional" fields would appear in real data.

## The seven operations

### 1) All contacts

```js
db.contactlist.find()
```

Returns the 5 seed documents, each stamped with the server-generated `_id: ObjectId(…)`.

### 2) One contact by `_id`

```js
const sample = db.contactlist.findOne();      // grab any existing _id
db.contactlist.findOne({ _id: sample._id });  // look it up explicitly
```

### 3) Age > 18

```js
db.contactlist.find({ age: { $gt: 18 } })
```

Returns **Ben (26)** and **Emilie (40)**. Kefi is 15 → excluded. Alex / Denzel are underage children → excluded.

### 4) Age > 18 AND name contains "ah" (case-insensitive)

```js
db.contactlist.find({
  age: { $gt: 18 },
  $or: [
    { firstName: { $regex: "ah", $options: "i" } },
    { lastName:  { $regex: "ah", $options: "i" } },
  ]
})
```

None of the sample names contain the literal substring `"ah"`, so the query returns **zero rows**. The script prints `(no matches)`. The point of the query is the *syntax* (compound `$and` with `$or`+`$regex`), not the specific match.

### 5) Rename Kefi Seif → Kefi Anis

```js
db.contactlist.updateOne(
  { lastName: "Kefi", firstName: "Seif" },
  { $set: { firstName: "Anis" } }
);
```

Verified: `matched: 1, modified: 1` and the follow-up `findOne` shows the updated document with `firstName: 'Anis'`.

### 6) Delete contacts with age < 5

```js
db.contactlist.deleteMany({ age: { $lt: 5 } });
```

Removes **Alex (4)** and **Denzel (3)** → `deletedCount: 2`.

### 7) All contacts (after delete)

Same `.find()` as step 1 — now returns 3 documents: Ben, Kefi (with firstName now "Anis"), and Emilie.

## Verified end-to-end

Executed against MongoDB 7 in Docker. The output in `expected_output.txt` is the real, unedited console output — steps 1-7 all behave as documented above.
