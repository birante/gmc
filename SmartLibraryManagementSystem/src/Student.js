import { User } from "./User.js";

export class Student extends User {
  #level;

  constructor(id, name, email, level = "Undergraduate") {
    super(id, name, email);
    this.#level = level;
  }

  get level() { return this.#level; }

  getRole() {
    return "Student";
  }

  getBorrowLimitDays() {
    return 14;
  }
}
