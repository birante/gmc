/**
 * Pure helper functions for working with grades.
 * Scores are numbers between 0 and 100 (inclusive).
 */

export const MIN_SCORE = 0;
export const MAX_SCORE = 100;

/** Letter-grade scale, checked from the top down. */
export const GRADE_SCALE = [
  { min: 90, letter: 'A' },
  { min: 80, letter: 'B' },
  { min: 70, letter: 'C' },
  { min: 60, letter: 'D' },
  { min: 0, letter: 'F' },
];

export const PASSING_SCORE = 60;

/**
 * Throws a helpful error when a score is not a valid number in [0, 100].
 * @param {unknown} score
 * @returns {number} the same score, so the call can be chained
 */
export function validateScore(score) {
  if (typeof score !== 'number' || Number.isNaN(score)) {
    throw new TypeError(`Score must be a number, received: ${String(score)}`);
  }
  if (score < MIN_SCORE || score > MAX_SCORE) {
    throw new RangeError(`Score must be between ${MIN_SCORE} and ${MAX_SCORE}, received: ${score}`);
  }
  return score;
}

/**
 * Rounds a number to a fixed number of decimals (default 2).
 * @param {number} value
 * @param {number} [decimals=2]
 */
export function round(value, decimals = 2) {
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
}

/**
 * Average of a list of scores. Returns null for an empty list.
 * @param {number[]} scores
 * @returns {number | null}
 */
export function average(scores) {
  if (!Array.isArray(scores)) {
    throw new TypeError('average() expects an array of scores');
  }
  if (scores.length === 0) {
    return null;
  }
  const total = scores.reduce((sum, score) => sum + validateScore(score), 0);
  return round(total / scores.length);
}

/**
 * Weighted average. Each item is { score, weight }.
 * Example: homework counts 1, exam counts 2.
 * @param {{ score: number, weight: number }[]} items
 * @returns {number | null}
 */
export function weightedAverage(items) {
  if (!Array.isArray(items)) {
    throw new TypeError('weightedAverage() expects an array of { score, weight }');
  }
  if (items.length === 0) {
    return null;
  }
  let total = 0;
  let totalWeight = 0;
  for (const { score, weight } of items) {
    validateScore(score);
    if (typeof weight !== 'number' || weight <= 0) {
      throw new RangeError(`Weight must be a positive number, received: ${String(weight)}`);
    }
    total += score * weight;
    totalWeight += weight;
  }
  return round(total / totalWeight);
}

/**
 * Converts a numeric score to a letter grade (A-F).
 * @param {number} score
 * @returns {'A' | 'B' | 'C' | 'D' | 'F'}
 */
export function letterGrade(score) {
  validateScore(score);
  const match = GRADE_SCALE.find((step) => score >= step.min);
  return /** @type {'A' | 'B' | 'C' | 'D' | 'F'} */ (match.letter);
}

/**
 * True when the score reaches the passing mark.
 * @param {number} score
 */
export function isPassing(score) {
  return validateScore(score) >= PASSING_SCORE;
}
