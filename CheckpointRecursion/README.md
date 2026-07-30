# Checkpoint Recursion — Is Palindrome

Palindrome checker written in JavaScript. A word is a palindrome iff it reads the same left-to-right and right-to-left (`gag`, `kayak`, `php`, `radar`, …).

## Run

```bash
node palindrome.js
# or
npm start
```

Requires Node.js 14+ (uses ES modules).

## Approach

Follows the brief exactly.

**Recursive step**
1. Compare the first and last character of the word.
2. If they differ → not a palindrome.
3. If they are equal → recurse on the same word stripped of its two ends.

**Base case**
- A word of length **0** or **1** is a palindrome (trivially).

```
isPalindrome("radar")
  → 'r' == 'r' → isPalindrome("ada")
    → 'a' == 'a' → isPalindrome("d")
      → length 1 → true
```

## Files

```
palindrome.js   -- recursive + iterative implementations, demo, exports
package.json    -- ES module config, `npm start` entry
README.md
```

## What's inside `palindrome.js`

| Function                       | Role                                                                 |
| ------------------------------ | -------------------------------------------------------------------- |
| `isPalindromeRecursive(word)`  | Main deliverable — pure recursion, matches the brief step-by-step.   |
| `isPalindromeIterative(word)`  | Loop-based version with two index counters walking toward each other — provided for comparison. |
| `normalize(word)`              | Lower-cases and strips non-alphanumeric characters. Used only in the extended demo (e.g. *"A man, a plan, a canal: Panama"*). |

## Example output

```
=== Recursive ===
  "gag"   -> true
  "kayak" -> true
  "php"   -> true
  "radar" -> true
  "hello" -> false
  ""      -> true
  "a"     -> true
  "ab"    -> false
  "abba"  -> true
  "abcba" -> true

=== With normalization (case + punctuation ignored) ===
  "Kayak"                          -> true
  "A man, a plan, a canal: Panama" -> true
  "No lemon, no melon"             -> true
  "Not a palindrome"               -> false
```

## Notes

- **Complexity** — both versions run in `O(n)` time. The recursive version uses `O(n)` extra stack space and `O(n²)` total substring allocation because `slice` copies; the iterative version is `O(1)` extra space.
- **Case sensitivity** — the raw functions are strict: `"Kayak"` is not equal to `"kayaK"` character-wise. Use `normalize()` first if case- and punctuation-insensitive matching is desired.
