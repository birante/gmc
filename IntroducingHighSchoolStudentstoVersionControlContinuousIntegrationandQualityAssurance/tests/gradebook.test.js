import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { Gradebook } from '../src/gradebook.js';

describe('Gradebook', () => {
  /** @type {Gradebook} */
  let book;

  beforeEach(() => {
    book = new Gradebook('Math 101');
  });

  describe('constructor', () => {
    it('stores a trimmed class name', () => {
      assert.equal(new Gradebook('  Physics  ').className, 'Physics');
    });

    it('rejects an empty class name', () => {
      assert.throws(() => new Gradebook(''), TypeError);
      assert.throws(() => new Gradebook(42), TypeError);
    });
  });

  describe('students', () => {
    it('adds students and supports chaining', () => {
      book.addStudent('Awa').addStudent('Moussa');
      assert.equal(book.students.size, 2);
    });

    it('refuses duplicate students (after trimming)', () => {
      book.addStudent('Awa');
      assert.throws(() => book.addStudent(' Awa '), /already exists/);
    });

    it('rejects invalid student names', () => {
      assert.throws(() => book.addStudent('   '), TypeError);
      assert.throws(() => book.addStudent(null), TypeError);
    });

    it('removes a student', () => {
      book.addStudent('Awa');
      assert.equal(book.removeStudent('Awa'), true);
      assert.equal(book.removeStudent('Awa'), false);
    });
  });

  describe('scores', () => {
    beforeEach(() => {
      book.addStudent('Awa');
    });

    it('records scores for a student', () => {
      book.addScore('Awa', 90).addScore('Awa', 80);
      assert.deepEqual(book.getScores('Awa'), [90, 80]);
    });

    it('returns a copy so callers cannot change internal state', () => {
      book.addScore('Awa', 90);
      book.getScores('Awa').push(0);
      assert.deepEqual(book.getScores('Awa'), [90]);
    });

    it('rejects invalid scores', () => {
      assert.throws(() => book.addScore('Awa', 150), RangeError);
      assert.throws(() => book.addScore('Awa', 'A'), TypeError);
    });

    it('throws for unknown students', () => {
      assert.throws(() => book.addScore('Nobody', 50), /Unknown student/);
    });

    it('computes a student average', () => {
      book.addScore('Awa', 90).addScore('Awa', 81);
      assert.equal(book.studentAverage('Awa'), 85.5);
    });

    it('returns null average for a student without scores', () => {
      assert.equal(book.studentAverage('Awa'), null);
    });
  });

  describe('class statistics', () => {
    it('returns null class average and top student when there are no scores', () => {
      book.addStudent('Awa');
      assert.equal(book.classAverage(), null);
      assert.equal(book.topStudent(), null);
    });

    it('averages student averages and ignores students without scores', () => {
      book.addStudent('Awa').addStudent('Moussa').addStudent('Empty');
      book.addScore('Awa', 100).addScore('Awa', 80); // 90
      book.addScore('Moussa', 70); // 70
      assert.equal(book.classAverage(), 80);
    });

    it('ranks students by average, breaking ties alphabetically', () => {
      book.addStudent('Zed').addStudent('Awa').addStudent('Fatou');
      book.addScore('Zed', 80).addScore('Awa', 80).addScore('Fatou', 95);
      assert.deepEqual(
        book.ranking().map((r) => [r.rank, r.name]),
        [
          [1, 'Fatou'],
          [2, 'Awa'],
          [3, 'Zed'],
        ],
      );
      assert.equal(book.topStudent().name, 'Fatou');
    });
  });

  describe('report', () => {
    it('builds a full report with letters and pass rate', () => {
      book.addStudent('Awa').addStudent('Moussa');
      book.addScore('Awa', 95).addScore('Moussa', 50);
      const report = book.report();
      assert.equal(report.className, 'Math 101');
      assert.equal(report.studentCount, 2);
      assert.equal(report.classAverage, 72.5);
      assert.equal(report.passRate, 50);
      assert.deepEqual(report.rows[0], { rank: 1, name: 'Awa', average: 95, letter: 'A', passing: true });
      assert.deepEqual(report.rows[1], { rank: 2, name: 'Moussa', average: 50, letter: 'F', passing: false });
    });

    it('has a null pass rate for an empty class', () => {
      assert.equal(book.report().passRate, null);
    });
  });

  describe('fromJSON', () => {
    it('creates a gradebook from plain data', () => {
      const loaded = Gradebook.fromJSON({ className: 'Bio', students: { Awa: [90, 70], Moussa: [] } });
      assert.equal(loaded.className, 'Bio');
      assert.equal(loaded.studentAverage('Awa'), 80);
      assert.deepEqual(loaded.getScores('Moussa'), []);
    });

    it('rejects malformed data', () => {
      assert.throws(() => Gradebook.fromJSON(null), TypeError);
      assert.throws(() => Gradebook.fromJSON({ className: 'Bio' }), TypeError);
      assert.throws(() => Gradebook.fromJSON({ className: 'Bio', students: null }), TypeError);
    });

    it('propagates invalid scores in the data', () => {
      assert.throws(() => Gradebook.fromJSON({ className: 'Bio', students: { Awa: [200] } }), RangeError);
    });
  });
});
