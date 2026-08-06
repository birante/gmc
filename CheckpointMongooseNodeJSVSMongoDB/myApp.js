// myApp.js — Mongoose CRUD checkpoint.
// Each exported function follows the brief's Node convention: takes a
// done(err, data) callback as its last argument.

// -----------------------------------------------------------------------
// 1) Setup — load env, connect, register the Person model.
// -----------------------------------------------------------------------
require("dotenv").config();
const mongoose = require("mongoose");

// The brief's recommended connect options. In Mongoose 6+ they are the
// defaults and no longer needed, but they are kept here to match the
// exact syntax the exercise asks for.
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Person schema — required name, optional age, optional list of foods.
const personSchema = new mongoose.Schema({
  name:          { type: String, required: true },
  age:            Number,
  favoriteFoods: [String],   // explicit [String] so no Mixed-type surprise
});

const Person = mongoose.model("Person", personSchema);

// -----------------------------------------------------------------------
// 2) Create and save a single Person via a document instance.
// -----------------------------------------------------------------------
const createAndSavePerson = (done) => {
  const person = new Person({
    name: "Alice Diop",
    age: 28,
    favoriteFoods: ["pizza", "pasta"],
  });
  person.save((err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 3) Create many people at once with Model.create.
// -----------------------------------------------------------------------
const createManyPeople = (arrayOfPeople, done) => {
  Person.create(arrayOfPeople, (err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 4) Find all people with a given name.
// -----------------------------------------------------------------------
const findPeopleByName = (personName, done) => {
  Person.find({ name: personName }, (err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 5) Find ONE person that has a given food in their favorites.
//    Mongoose translates a scalar match against an array field into an
//    element-wise $in — { favoriteFoods: food } matches any person whose
//    favoriteFoods array contains `food`.
// -----------------------------------------------------------------------
const findOneByFood = (food, done) => {
  Person.findOne({ favoriteFoods: food }, (err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 6) Find a person by its _id.
// -----------------------------------------------------------------------
const findPersonById = (personId, done) => {
  Person.findById(personId, (err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 7) Classic find → edit → save.
//    Add "hamburger" to the person's favoriteFoods array, then save.
//    Because favoriteFoods is declared as [String] (not Mixed) Mongoose
//    tracks the change on its own, no need to call markModified().
// -----------------------------------------------------------------------
const findEditThenSave = (personId, done) => {
  Person.findById(personId, (err, person) => {
    if (err) return done(err);
    if (!person) return done(new Error(`No person with id ${personId}`));
    person.favoriteFoods.push("hamburger");
    person.save((err, updated) => {
      if (err) return done(err);
      done(null, updated);
    });
  });
};

// -----------------------------------------------------------------------
// 8) New-style atomic update via findOneAndUpdate.
//    { new: true } forces the returned document to be the UPDATED one
//    (the default is the pre-update snapshot).
// -----------------------------------------------------------------------
const findAndUpdate = (personName, done) => {
  Person.findOneAndUpdate(
    { name: personName },
    { age: 20 },
    { new: true },
    (err, data) => {
      if (err) return done(err);
      done(null, data);
    }
  );
};

// -----------------------------------------------------------------------
// 9) Delete a person by _id via findByIdAndRemove.
// -----------------------------------------------------------------------
const removeById = (personId, done) => {
  Person.findByIdAndRemove(personId, (err, data) => {
    if (err) return done(err);
    done(null, data);
  });
};

// -----------------------------------------------------------------------
// 10) Delete every person named "Mary" via Model.remove.
//     .remove is deprecated (superseded by .deleteMany), but the brief
//     asks for it explicitly. It returns a summary object, not the docs.
// -----------------------------------------------------------------------
const removeManyPeople = (done) => {
  Person.remove({ name: "Mary" }, (err, result) => {
    if (err) return done(err);
    done(null, result);
  });
};

// -----------------------------------------------------------------------
// 11) Chained query helpers.
//     Find burrito lovers, sort by name, take up to 2, hide the age.
//     .exec() runs the assembled query and passes (err, data) to the cb.
// -----------------------------------------------------------------------
const queryChain = (done) => {
  const foodToSearch = "burrito";
  Person
    .find({ favoriteFoods: foodToSearch })
    .sort({ name: 1 })       // A -> Z
    .limit(2)                // top 2 hits
    .select({ age: 0 })      // omit the age field from the projection
    .exec((err, data) => {
      if (err) return done(err);
      done(null, data);
    });
};

// -----------------------------------------------------------------------
// Exports — every function follows the (done) or (input, done) shape
// so demo.js (and any test harness) can chain them.
// -----------------------------------------------------------------------
module.exports = {
  Person,
  createAndSavePerson,
  createManyPeople,
  findPeopleByName,
  findOneByFood,
  findPersonById,
  findEditThenSave,
  findAndUpdate,
  removeById,
  removeManyPeople,
  queryChain,
};
