import { validateScore, round, MAX_SCORE } from './grades.js';

/**
 * "Curves" a list of scores: adds the same bonus to every score so that
 * the best score becomes 100. Scores are never lowered.
 * @param {number[]} scores
 * @returns {number[]}
 */
export function curveScores(scores) {
  if (!Array.isArray(scores)) {
    throw new TypeError('curveScores() expects an array of scores');
  }
  if (scores.length === 0) {
    return [];
  }
  scores.forEach(validateScore);
  const best = Math.max(...scores);
  const bonus = MAX_SCORE - best;
  return scores.map((score) => round(score + bonus));
}
