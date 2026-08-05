// MongoDB CRUD checkpoint — mongosh script.
// Run against any MongoDB with:
//   mongosh mongodb://127.0.0.1:27017/contact contact.js
//
// The connection string already selects the "contact" database, so `db`
// resolves to it and every command below targets db.contactlist.

// --- reset -------------------------------------------------------------
// Drop the collection first so re-runs are idempotent (the brief's
// "insert 5 documents" would otherwise pile up on repeat runs).
db.contactlist.drop();

// --- seed --------------------------------------------------------------
// Insert the 5 documents from the brief.
db.contactlist.insertMany([
  { lastName: "Ben",    firstName: "Moris",      email: "ben@gmail.com",       age: 26 },
  { lastName: "Kefi",   firstName: "Seif",       email: "kefi@gmail.com",      age: 15 },
  { lastName: "Emilie", firstName: "brouge",     email: "emilie.b@gmail.com",  age: 40 },
  { lastName: "Alex",   firstName: "brown",                                     age: 4  },
  { lastName: "Denzel", firstName: "Washington",                                age: 3  },
]);

const line = (n, title) => print(`\n----- ${n}) ${title} -----`);

// -----------------------------------------------------------------------
// 1) Display all contacts
// -----------------------------------------------------------------------
line(1, "All contacts");
db.contactlist.find().forEach(d => printjson(d));

// -----------------------------------------------------------------------
// 2) Fetch one contact by ID
//    Grab any existing _id, then look it up explicitly.
// -----------------------------------------------------------------------
line(2, "One contact by _id");
const sample = db.contactlist.findOne();
printjson(db.contactlist.findOne({ _id: sample._id }));

// -----------------------------------------------------------------------
// 3) Age > 18
// -----------------------------------------------------------------------
line(3, "Contacts with age > 18");
db.contactlist.find({ age: { $gt: 18 } }).forEach(d => printjson(d));

// -----------------------------------------------------------------------
// 4) Age > 18 AND (first or last name contains "ah", case-insensitive)
//    None of the sample names contain "ah" — the query returns nothing,
//    which is the correct answer for the given input.
// -----------------------------------------------------------------------
line(4, "Age > 18 AND name contains 'ah'");
const matches = db.contactlist.find({
  age: { $gt: 18 },
  $or: [
    { firstName: { $regex: "ah", $options: "i" } },
    { lastName:  { $regex: "ah", $options: "i" } },
  ],
}).toArray();
if (matches.length === 0) print("(no matches)");
matches.forEach(d => printjson(d));

// -----------------------------------------------------------------------
// 5) Rename Kefi's first name Seif -> Anis
// -----------------------------------------------------------------------
line(5, "Update Kefi Seif -> Kefi Anis");
const updateRes = db.contactlist.updateOne(
  { lastName: "Kefi", firstName: "Seif" },
  { $set: { firstName: "Anis" } }
);
print(`matched: ${updateRes.matchedCount}, modified: ${updateRes.modifiedCount}`);
printjson(db.contactlist.findOne({ lastName: "Kefi" }));

// -----------------------------------------------------------------------
// 6) Delete contacts with age < 5
// -----------------------------------------------------------------------
line(6, "Delete contacts with age < 5");
const delRes = db.contactlist.deleteMany({ age: { $lt: 5 } });
print(`deleted: ${delRes.deletedCount}`);

// -----------------------------------------------------------------------
// 7) Display all contacts (after delete)
// -----------------------------------------------------------------------
line(7, "All contacts (after delete)");
db.contactlist.find().forEach(d => printjson(d));
