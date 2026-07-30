// Factory Pattern — hides the plan selection and ID allocation.
// Takes an IdGenerator so tests can drive deterministic IDs.

import { Member, Plans } from "../models/Member.js";

export class MemberFactory {
  #idGenerator;

  constructor(idGenerator) {
    this.#idGenerator = idGenerator;
  }

  create(kind, { name, email } = {}) {
    if (!name || !email) throw new Error("name and email are required.");
    const plan = this.#planFor(kind);
    return new Member({ id: this.#idGenerator.nextId(), name, email, plan });
  }

  createStudent(details) { return this.create("student", details); }
  createTeacher(details) { return this.create("teacher", details); }

  #planFor(kind) {
    const key = String(kind).toUpperCase();
    const plan = Plans[key];
    if (!plan) throw new Error(`Unknown member kind: ${kind}`);
    return plan;
  }
}
