# Checkpoint — Asynchronous Programming in JavaScript

Five async/await tasks (the brief asks for at least three; all five are solved because they build on each other pedagogically).

## Run

```bash
npm start        # runs all five tasks back-to-back (~8 s total)
npm run task01   # just Task 1
npm run task02   # just Task 2
# … etc.
```

Requires Node.js **≥ 14** (ES modules and `import.meta.url`).

## Task index

| # | File            | Function(s) exported                                | Concept              |
| - | --------------- | --------------------------------------------------- | -------------------- |
| 1 | `src/task01.js` | `iterateWithAsyncAwait(values)`                     | Sequential iteration with a delay |
| 2 | `src/task02.js` | `awaitCall(url)`                                    | Awaiting a promise   |
| 3 | `src/task03.js` | `awaitCallSafe(url, opts)`, `chainedAsyncFunctions()` | try/catch + sequential chain |
| 4 | `src/task04.js` | `concurrentRequests()`                              | `Promise.all` on 2 calls |
| 5 | `src/task05.js` | `parallelCalls(urls)`, `parallelCallsSettled(urls, failIndices)` | Parallel batch, incl. `Promise.allSettled` variant |

Shared helper: `src/utils.js` (a `sleep(ms)` and a `fakeFetch(url, opts)` that resolves/rejects after ~500 ms — everything runs offline).

## Key ideas one place at a time

**Task 1 — a `for … of` loop with `await sleep(1000)` gives you sequential pauses.** Using `.forEach` here would silently *not* wait, because the callback returns a promise that `.forEach` ignores.

**Task 2 — `await` suspends the async function** until the promise settles; the rest of the event loop keeps running in the meantime.

**Task 3 — errors from a rejected promise surface as thrown exceptions inside the `async` function**, so `try/catch` handles them just like sync errors. `chainedAsyncFunctions` shows the *sequential* pattern: each `await` blocks the *next* line, not the whole runtime.

**Task 4 — `Promise.all([a(), b()])` starts both calls before awaiting either.** The demo prints an elapsed time of ~500 ms even though each fake fetch takes 500 ms — the two overlap.

**Task 5 — `urls.map(fakeFetch)` fires every request synchronously**, producing an array of pending promises; `Promise.all` awaits the whole batch. The bonus `parallelCallsSettled` uses `Promise.allSettled` to tolerate partial failures — Promise.all rejects on the *first* failure and abandons the rest, which is often not what you want in a batch job.

## Sample output (excerpt)

```
=== Task 04 — concurrentRequests ===
[concurrentRequests] both resolved in ~502 ms
[concurrentRequests] combined: {
  users: { message: 'payload from https://api.example.com/users' },
  posts: { message: 'payload from https://api.example.com/posts' }
}

=== Task 05b — parallelCallsSettled (one of three fails) ===
[parallelCallsSettled] 2 ok, 1 failed.
  failures: [ 'Network error on https://api.example.com/b' ]
```

## Sequential vs concurrent — quick reference

```js
// Sequential — total ≈ sum of each call's time
const a = await fetchThing();
const b = await fetchThing();

// Concurrent — total ≈ max of the two times (start both, then wait)
const [a, b] = await Promise.all([fetchThing(), fetchThing()]);

// Concurrent + fault-tolerant — total ≈ max, but never throws
const results = await Promise.allSettled([fetchThing(), fetchThing()]);
```
