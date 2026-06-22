# Checkpoint: Decision Making and Recursive Algorithms

## Objective

Two short topics in one checkpoint:

- **Decision making** — practice picking the right branching construct
  (`if`/`else if` for ranges and compound conditions, `switch` for a small
  fixed set of discrete categories).
- **Recursion** — practice breaking a problem into a **base case** plus a
  **smaller-instance recursive case**, and recognising when plain
  recursion is fine (small inputs) vs. when memoisation or
  fast-exponentiation is required (large inputs).

The brief asks for at least 2 + 2 tasks; this checkpoint solves **all six**
in a single file so the trade-offs (e.g. plain Fibonacci vs. memoised
Fibonacci, plain `power` vs. `fastPower`) can be shown side-by-side.

## How to Run

```bash
node decisionsAndRecursion.js
```

---

## Part 1 — Decision Making

### 1.1 Leap Year Checker

Rule: a year is a leap year iff `(year % 4 === 0 && year % 100 !== 0) || year % 400 === 0`.
Written as three early returns, in the order that mirrors the calendar rule
the user is likely to remember:

```js
function isLeapYear(year) {
    if (!Number.isInteger(year)) return false;
    if (year % 400 === 0) return true;
    if (year % 100 === 0) return false;
    if (year % 4 === 0)   return true;
    return false;
}
```

Sample output:

```
1600 → leap year       1700 → not a leap year   1900 → not a leap year
2000 → leap year       2024 → leap year         2025 → not a leap year
2100 → not a leap year 2400 → leap year
```

### 1.2 Ticket Pricing

`if`/`else if` is the natural fit for the **age ranges** (`<=12`, `13-17`,
`>=18`). Once we know the bucket, the `switch` cleanly maps the discrete
category to its price — this is the textbook case for `switch`: a small,
fixed, exhaustive enum.

```js
function ticketPrice(age) {
    if (!Number.isInteger(age) || age < 0) return null;

    let bucket;
    if (age <= 12) bucket = "child";
    else if (age <= 17) bucket = "teen";
    else bucket = "adult";

    switch (bucket) {
        case "child": return 10;
        case "teen":  return 15;
        case "adult": return 20;
    }
}
```

Sample output:

```
age  5 → $10   age 12 → $10   age 13 → $15   age 17 → $15
age 18 → $20   age 40 → $20   age 99 → $20
```

### 1.3 Weather Clothing Adviser

Two inputs: `temperatureC` (number) and `raining` (boolean). The
temperature picks a base outfit from five ranges; rain appends an umbrella
note.

```js
function clothingAdvice(temperatureC, raining) {
    let base;
    if (temperatureC < 0)       base = "Heavy coat, hat and gloves";
    else if (temperatureC < 10) base = "Warm jacket and a scarf";
    else if (temperatureC < 18) base = "Light jacket or sweater";
    else if (temperatureC < 26) base = "T-shirt and jeans";
    else                        base = "Shorts and a light t-shirt";

    return raining ? `${base}, plus an umbrella and waterproof shoes` : base;
}
```

Sample output:

```
 -5°C, dry      → Heavy coat, hat and gloves
 -5°C, raining  → Heavy coat, hat and gloves, plus an umbrella and waterproof shoes
 15°C, raining  → Light jacket or sweater, plus an umbrella and waterproof shoes
 30°C, raining  → Shorts and a light t-shirt, plus an umbrella and waterproof shoes
```

---

## Part 2 — Recursion

Every recursive solution below follows the same shape:

1. **Base case** — the smallest input we can answer directly.
2. **Recursive case** — reduce to a strictly smaller input and combine.

### 2.1 Fibonacci

```js
function fibonacci(n) {
    if (n < 0) return null;
    if (n < 2) return n;                       // base case: fib(0)=0, fib(1)=1
    return fibonacci(n - 1) + fibonacci(n - 2);
}
```

The naive version is `O(2^n)` because it re-computes the same sub-problems
exponentially many times — `fib(35)` already takes a noticeable pause, and
`fib(50)` is effectively unreachable. A memoised variant — same recursion,
but cached — is `O(n)`:

```js
function fibonacciMemo(n, cache = new Map()) {
    if (n < 0) return null;
    if (n < 2) return n;
    if (cache.has(n)) return cache.get(n);
    const value = fibonacciMemo(n - 1, cache) + fibonacciMemo(n - 2, cache);
    cache.set(n, value);
    return value;
}
```

`fibonacciMemo(50) = 12586269025` returns in microseconds; the plain
`fibonacci(50)` would take minutes.

### 2.2 Palindrome Checker

Strip out non-alphanumerics, lower-case, then recursively compare the ends
and shrink the window inward:

```js
function isPalindrome(input) {
    const cleaned = String(input).toLowerCase().replace(/[^a-z0-9]/g, "");
    return checkPalindrome(cleaned, 0, cleaned.length - 1);
}

function checkPalindrome(s, left, right) {
    if (left >= right) return true;                 // base case: pointers met
    if (s[left] !== s[right]) return false;         // mismatch at the ends
    return checkPalindrome(s, left + 1, right - 1); // recurse inward
}
```

Sample output:

```
YES — "racecar"
YES — "A man, a plan, a canal: Panama"
YES — "No 'x' in Nixon"
YES — "Was it a car or a cat I saw?"
NO  — "hello"
NO  — "definitely not"
YES — ""           (empty string is trivially a palindrome)
```

Time/space: `O(n)` time, `O(n)` recursion depth.

### 2.3 Power Function

Three cases handle every real exponent:

- `n === 0` → return `1` (base case).
- `n < 0`   → return `1 / power(base, -n)` (sign reduction).
- `n > 0`   → return `base * power(base, n - 1)` (recursive case).

```js
function power(base, exponent) {
    if (exponent === 0) return 1;
    if (exponent < 0) return 1 / power(base, -exponent);
    return base * power(base, exponent - 1);
}
```

This is `O(n)` recursion depth. For large exponents the classic
fast-exponentiation trick — `b^n = (b^(n/2))^2` (or `b * (b^(n/2))^2` when
`n` is odd) — drops the depth to `O(log n)`:

```js
function fastPower(base, exponent) {
    if (exponent === 0) return 1;
    if (exponent < 0) return 1 / fastPower(base, -exponent);
    const half = fastPower(base, Math.floor(exponent / 2));
    return exponent % 2 === 0 ? half * half : half * half * base;
}
```

Sample output (both functions agree on every input):

```
power(2, 10)     = 1024       fastPower(2, 10) = 1024
power(3, 5)      = 243        fastPower(3, 5)  = 243
power(5, 0)      = 1          fastPower(5, 0)  = 1
power(2, -3)     = 0.125      fastPower(2, -3) = 0.125
power(1.5, 4)    = 5.0625     fastPower(1.5, 4)= 5.0625
```

---

## Summary

| Task                  | Construct                | Notes                                |
|-----------------------|--------------------------|--------------------------------------|
| Leap Year Checker     | `if` / early returns     | Order matches the calendar rule      |
| Ticket Pricing        | `if` + `switch`          | `if` for ranges, `switch` for buckets |
| Weather Clothing      | `if` / `else if` + ternary | Five temperature ranges + rain flag |
| Fibonacci             | Recursion + memoisation  | O(2^n) → O(n) with a cache           |
| Palindrome Checker    | Two-pointer recursion    | Strips non-alphanumerics first       |
| Power Function        | Recursion + fast-exp     | O(n) → O(log n) with `half * half`   |
