import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { curveScores } from '../src/curve.js';

describe('curveScores', () => {
  it('raises every score so the best becomes 100', () => {
    assert.deepEqual(curveScores([70, 85, 90]), [80, 95, 100]);
  });

  it('leaves scores unchanged when someone already has 100', () => {
    assert.deepEqual(curveScores([100, 50]), [100, 50]);
  });

  it('keeps decimals tidy', () => {
    assert.deepEqual(curveScores([33.333, 66.666]), [66.67, 100]);
  });

  it('returns an empty list for an empty input', () => {
    assert.deepEqual(curveScores([]), []);
  });

  it('rejects bad input', () => {
    assert.throws(() => curveScores('90'), TypeError);
    assert.throws(() => curveScores([90, -5]), RangeError);
  });
});
