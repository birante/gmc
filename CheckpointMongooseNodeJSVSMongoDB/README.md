# Mongoose Node.js vs MongoDB — Checkpoint

Ten guided Mongoose CRUD exercises, all in one file (`myApp.js`), each preserving the `function(err, data)` callback signature the brief asks for. `demo.js` chains them against a real MongoDB and prints one line per exercise so success is self-evident.

## Run

```bash
cp .env.example .env       # point MONGO_URI at your database
npm install
npm start                  # runs demo.js against $MONGO_URI
```

No MongoDB handy? Quickest path:

```bash
docker run -d --rm --name mongo -p 27017:27017 mongo:7
```

## Why Mongoose 6?

The brief uses:

- `function(err, data)` node-style callbacks on `.save()`, `.find()`, `.findOne()`, `.findById()`, `.findOneAndUpdate()`, `.findByIdAndRemove()`, `.remove()`, `.exec()`
- `useNewUrlParser: true, useUnifiedTopology: true`
- `Model.remove()`

All three were removed in **Mongoose 7** (July 2022). To match the brief faithfully — same callbacks, same options, same `.remove()` — this checkpoint pins **Mongoose 6.12** (the last v6, released Sep 2023, still installable and compatible with MongoDB 7).

If you would rather use modern Mongoose 8, the exact same functions work when returning promises and calling `.deleteMany()` instead of `.remove()`; the demo already promise-wraps the callbacks so the migration is mechanical.

## Files

```
myApp.js             -- the 10 exercises, each a callback-style function
demo.js              -- runs every function end-to-end
expected_output.txt  -- captured console output from a real run
.env.example         -- MONGO_URI template
```

## The 10 exercises

| # | Function                       | What it does                                                                          |
| - | ------------------------------ | ------------------------------------------------------------------------------------- |
| 1 | `createAndSavePerson`          | New `Person(...)` + `.save(cb)`                                                       |
| 2 | `createManyPeople(arr, cb)`    | `Person.create(arr, cb)` bulk insert                                                  |
| 3 | `findPeopleByName(name, cb)`   | `Person.find({name}, cb)` returns an array                                            |
| 4 | `findOneByFood(food, cb)`      | `Person.findOne({favoriteFoods: food}, cb)` — array-contains via a scalar predicate   |
| 5 | `findPersonById(id, cb)`       | `Person.findById(id, cb)`                                                             |
| 6 | `findEditThenSave(id, cb)`     | `findById` → `push("hamburger")` → `.save`                                            |
| 7 | `findAndUpdate(name, cb)`      | `findOneAndUpdate({name}, {age: 20}, {new: true}, cb)` — `new: true` returns the updated doc |
| 8 | `removeById(id, cb)`           | `findByIdAndRemove(id, cb)`                                                           |
| 9 | `removeManyPeople(cb)`         | `Person.remove({name: 'Mary'}, cb)` — returns a summary, not documents                |
| 10| `queryChain(cb)`               | `.find().sort().limit().select().exec(cb)` for burrito lovers, sorted, age hidden      |

## Expected output

Captured from an actual run against a MongoDB 7 container:

```
1) createAndSavePerson -> Alice Diop 6a74fa3ebd52927c5b954af0
2) createManyPeople   -> inserted 4
3) findPeopleByName   -> 2 Marys
4) findOneByFood      -> Alice Diop likes pizza
5) findPersonById     -> Alice Diop
6) findEditThenSave   -> Alice Diop now likes pizza, pasta, hamburger
7) findAndUpdate      -> Bob's age is now 20
8) removeById         -> removed Alice Diop
9) removeManyPeople   -> deletedCount=2
10) queryChain        -> 2 result(s)
    - Bob, age hidden=true
    - Charlie, age hidden=true
```

The two Mongoose warnings (`strictQuery` and `collection.remove is deprecated`) are Mongoose 6's way of nudging you to upgrade. Harmless.

## Person schema

```js
const personSchema = new mongoose.Schema({
  name:          { type: String, required: true },
  age:           Number,
  favoriteFoods: [String],   // explicit [String] avoids the Mixed-type gotcha
});
```

`favoriteFoods` is declared as `[String]` — not the bare `Array` the brief warns about — so exercise 6 does *not* need `markModified()`. Mongoose tracks the `.push()` on its own.
