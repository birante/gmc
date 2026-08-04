// Task 01 — Iterating with Async/Await.
//
// A plain `for … of` loop with `await sleep(1000)` inside makes the
// pause happen sequentially between logs. Using .forEach here would
// NOT wait — the callback returns a promise that forEach ignores.

import { sleep } from "./utils.js";

export async function iterateWithAsyncAwait(values) {
  for (const value of values) {
    await sleep(1000);
    console.log(value);
  }
}

// Run directly with:  node src/task01.js
if (import.meta.url === `file://${process.argv[1]}`) {
  await iterateWithAsyncAwait(["one", "two", "three"]);
}
