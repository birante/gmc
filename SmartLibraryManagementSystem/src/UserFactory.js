import { Student } from "./Student.js";
import { Teacher } from "./Teacher.js";

export class UserFactory {
  static #nextId = 1;

  static createUser(type, { name, email, level, department } = {}) {
    if (!name || !email) {
      throw new Error("name and email are required to create a user.");
    }
    const id = `U-${String(UserFactory.#nextId++).padStart(4, "0")}`;
    const kind = String(type).toLowerCase();
    switch (kind) {
      case "student":
        return new Student(id, name, email, level);
      case "teacher":
        return new Teacher(id, name, email, department);
      default:
        throw new Error(`Unknown user type: ${type}. Expected "student" or "teacher".`);
    }
  }
}
