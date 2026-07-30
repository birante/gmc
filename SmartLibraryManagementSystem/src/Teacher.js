import { User } from "./User.js";

export class Teacher extends User {
  #department;

  constructor(id, name, email, department = "General") {
    super(id, name, email);
    this.#department = department;
  }

  get department() { return this.#department; }

  getRole() {
    return "Teacher";
  }

  getBorrowLimitDays() {
    return 30;
  }
}
