// demo.js — exercises every function in myApp.js in sequence.
// Wraps each callback-style function in a Promise so the top-level flow
// can use async/await for readability.

const mongoose = require("mongoose");
const app = require("./myApp");

// Turn a function whose last argument is `done(err, data)` into a promise.
const p = (fn, ...args) =>
  new Promise((resolve, reject) =>
    fn(...args, (err, data) => (err ? reject(err) : resolve(data))));

async function main() {
  // Clean slate so re-runs are idempotent.
  await app.Person.deleteMany({});

  // 1) Create and save one Person
  const alice = await p(app.createAndSavePerson);
  console.log("1) createAndSavePerson ->", alice.name, alice._id.toString());

  // 2) Create many
  const many = await p(app.createManyPeople, [
    { name: "Mary",  age: 30, favoriteFoods: ["burrito", "pizza"] },
    { name: "Mary",  age: 45, favoriteFoods: ["pasta"] },
    { name: "Bob",   age: 25, favoriteFoods: ["burrito", "sushi"] },
    { name: "Charlie", age: 33, favoriteFoods: ["burrito"] },
  ]);
  console.log(`2) createManyPeople   -> inserted ${many.length}`);

  // 3) Find by name
  const marys = await p(app.findPeopleByName, "Mary");
  console.log(`3) findPeopleByName   -> ${marys.length} Marys`);

  // 4) Find one by favourite food
  const pizzaFan = await p(app.findOneByFood, "pizza");
  console.log(`4) findOneByFood      -> ${pizzaFan?.name} likes pizza`);

  // 5) Find by _id
  const fetched = await p(app.findPersonById, alice._id);
  console.log(`5) findPersonById     -> ${fetched.name}`);

  // 6) findEditThenSave adds "hamburger"
  const withHamburger = await p(app.findEditThenSave, alice._id);
  console.log(`6) findEditThenSave   -> ${alice.name} now likes ${withHamburger.favoriteFoods.join(", ")}`);

  // 7) findAndUpdate sets Bob's age to 20
  const updatedBob = await p(app.findAndUpdate, "Bob");
  console.log(`7) findAndUpdate      -> Bob's age is now ${updatedBob.age}`);

  // 8) removeById drops Alice
  const removedAlice = await p(app.removeById, alice._id);
  console.log(`8) removeById         -> removed ${removedAlice.name}`);

  // 9) removeManyPeople drops every Mary and returns a summary
  const maryDrop = await p(app.removeManyPeople);
  console.log(`9) removeManyPeople   -> deletedCount=${maryDrop.deletedCount ?? maryDrop.n}`);

  // 10) Query chain: burrito lovers, sorted, limited to 2, no age
  const burritoLovers = await p(app.queryChain);
  console.log(`10) queryChain        -> ${burritoLovers.length} result(s)`);
  burritoLovers.forEach(d => console.log(`    - ${d.name}, age hidden=${d.age === undefined}`));

  await mongoose.disconnect();
}

main().catch(err => {
  console.error("demo failed:", err);
  mongoose.disconnect().finally(() => process.exit(1));
});
