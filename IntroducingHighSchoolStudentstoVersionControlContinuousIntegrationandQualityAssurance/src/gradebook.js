import { average, letterGrade, isPassing, validateScore, round } from './grades.js';

/**
 * A small in-memory gradebook for one class.
 *
 * const book = new Gradebook('Math 101');
 * book.addStudent('Awa');
 * book.addScore('Awa', 95);
 * book.report();
 */
export class Gradebook {
  /** @param {string} className */
  constructor(className) {
    if (typeof className !== 'string' || className.trim() === '') {
      throw new TypeError('Class name must be a non-empty string');
    }
    this.className = className.trim();
    /** @type {Map<string, number[]>} */
    this.students = new Map();
  }

  /** @param {string} name */
  addStudent(name) {
    const key = Gradebook.normalizeName(name);
    if (this.students.has(key)) {
      throw new Error(`Student "${key}" already exists`);
    }
    this.students.set(key, []);
    return this;
  }

  /** @param {string} name */
  removeStudent(name) {
    const key = Gradebook.normalizeName(name);
    return this.students.delete(key);
  }

  /**
   * @param {string} name
   * @param {number} score
   */
  addScore(name, score) {
    const scores = this.#getScores(name);
    scores.push(validateScore(score));
    return this;
  }

  /** @param {string} name */
  getScores(name) {
    return [...this.#getScores(name)];
  }

  /** @param {string} name */
  studentAverage(name) {
    return average(this.#getScores(name));
  }

  /** Average of all student averages (students without scores are ignored). */
  classAverage() {
    const averages = this.#studentAverages().map((entry) => entry.average);
    return averages.length === 0 ? null : round(averages.reduce((a, b) => a + b, 0) / averages.length);
  }

  /** Students sorted from the highest to the lowest average. */
  ranking() {
    return this.#studentAverages()
      .sort((a, b) => b.average - a.average || a.name.localeCompare(b.name))
      .map((entry, index) => ({ rank: index + 1, ...entry }));
  }

  /** The best student, or null if nobody has scores yet. */
  topStudent() {
    const [first] = this.ranking();
    return first ?? null;
  }

  /** A plain-object summary that is easy to print or turn into JSON. */
  report() {
    const rows = this.ranking().map((entry) => ({
      ...entry,
      letter: letterGrade(entry.average),
      passing: isPassing(entry.average),
    }));
    const passed = rows.filter((row) => row.passing).length;
    return {
      className: this.className,
      studentCount: this.students.size,
      classAverage: this.classAverage(),
      passRate: rows.length === 0 ? null : round((passed / rows.length) * 100),
      rows,
    };
  }

  /**
   * Builds a gradebook from plain data: { className, students: { name: [scores] } }
   * @param {{ className: string, students: Record<string, number[]> }} data
   */
  static fromJSON(data) {
    if (!data || typeof data !== 'object' || typeof data.students !== 'object' || data.students === null) {
      throw new TypeError('Data must look like { className, students: { name: [scores] } }');
    }
    const book = new Gradebook(data.className);
    for (const [name, scores] of Object.entries(data.students)) {
      book.addStudent(name);
      for (const score of scores) {
        book.addScore(name, score);
      }
    }
    return book;
  }

  /** @param {unknown} name */
  static normalizeName(name) {
    if (typeof name !== 'string' || name.trim() === '') {
      throw new TypeError('Student name must be a non-empty string');
    }
    return name.trim();
  }

  /** @param {string} name */
  #getScores(name) {
    const key = Gradebook.normalizeName(name);
    const scores = this.students.get(key);
    if (!scores) {
      throw new Error(`Unknown student "${key}"`);
    }
    return scores;
  }

  #studentAverages() {
    const result = [];
    for (const [name, scores] of this.students) {
      if (scores.length > 0) {
        result.push({ name, average: average(scores) });
      }
    }
    return result;
  }
}
