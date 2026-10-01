import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { validateScore, round, average, weightedAverage, letterGrade, isPassing } from '../src/grades.js';

describe('validateScore', () => {
  it('accepts scores between 0 and 100', () => {
    assert.equal(validateScore(0), 0);
    assert.equal(validateScore(55.5), 55.5);
    assert.equal(validateScore(100), 100);
  });

  it('rejects values that are not numbers', () => {
    assert.throws(() => validateScore('90'), TypeError);
    assert.throws(() => validateScore(NaN), TypeError);
    assert.throws(() => validateScore(undefined), TypeError);
  });

  it('rejects scores outside 0-100', () => {
    assert.throws(() => validateScore(-1), RangeError);
    assert.throws(() => validateScore(100.1), RangeError);
  });
});

describe('round', () => {
  it('rounds to 2 decimals by default', () => {
    assert.equal(round(86.666), 86.67);
  });

  it('supports a custom number of decimals', () => {
    assert.equal(round(86.666, 0), 87);
    assert.equal(round(86.666, 1), 86.7);
  });
});

describe('average', () => {
  it('computes the mean of a list of scores', () => {
    assert.equal(average([80, 90, 100]), 90);
    assert.equal(average([70, 75]), 72.5);
  });

  it('returns null for an empty list', () => {
    assert.equal(average([]), null);
  });

  it('throws when given something that is not an array', () => {
    assert.throws(() => average('80,90'), TypeError);
  });

  it('throws when the list contains an invalid score', () => {
    assert.throws(() => average([80, 120]), RangeError);
  });
});

describe('weightedAverage', () => {
  it('gives more importance to heavier items', () => {
    const result = weightedAverage([
      { score: 60, weight: 1 },
      { score: 90, weight: 2 },
    ]);
    assert.equal(result, 80);
  });

  it('returns null for an empty list', () => {
    assert.equal(weightedAverage([]), null);
  });

  it('rejects non-array input', () => {
    assert.throws(() => weightedAverage(null), TypeError);
  });

  it('rejects zero, negative or missing weights', () => {
    assert.throws(() => weightedAverage([{ score: 80, weight: 0 }]), RangeError);
    assert.throws(() => weightedAverage([{ score: 80, weight: -2 }]), RangeError);
    assert.throws(() => weightedAverage([{ score: 80 }]), RangeError);
  });
});

describe('letterGrade', () => {
  const cases = [
    [100, 'A'],
    [90, 'A'],
    [89.99, 'B'],
    [80, 'B'],
    [79, 'C'],
    [70, 'C'],
    [69, 'D'],
    [60, 'D'],
    [59.9, 'F'],
    [0, 'F'],
  ];
  for (const [score, expected] of cases) {
    it(`maps ${score} to ${expected}`, () => {
      assert.equal(letterGrade(score), expected);
    });
  }

  it('throws on invalid scores', () => {
    assert.throws(() => letterGrade(101), RangeError);
  });
});

describe('isPassing', () => {
  it('passes at 60 and above', () => {
    assert.equal(isPassing(60), true);
    assert.equal(isPassing(99), true);
  });

  it('fails below 60', () => {
    assert.equal(isPassing(59.99), false);
  });
});
