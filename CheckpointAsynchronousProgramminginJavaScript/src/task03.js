// Task 03 — Error handling + Chaining Async/Await.
//
// Two things demonstrated here:
//   1) awaitCallSafe wraps the await in try/catch — any rejection is
//      captured as a normal exception, so the caller never sees an
//      unhandled promise rejection.
//   2) chainedAsyncFunctions awaits three steps in sequence — each one
//      only starts once the previous has fully resolved. That's the
//      opposite of Promise.all() (see Tasks 4 and 5).

import { fakeFetch, sleep } from "./utils.js";

export async function awaitCallSafe(url = "https://api.example.com/todo/1", opts = {}) {
  try {
    const response = await fakeFetch(url, opts);
    console.log("[awaitCallSafe] data received:", response.data);
    return response.data;
  } catch (err) {
    console.error(`[awaitCallSafe] Sorry, we couldn't fetch the data (${err.message}). Please try again later.`);
    return null;
  }
}

async function step1() { await sleep(1000); console.log("[chain] step 1 done"); }
async function step2() { await sleep(1000); console.log("[chain] step 2 done"); }
async function step3() { await sleep(1000); console.log("[chain] step 3 done"); }

export async function chainedAsyncFunctions() {
  await step1();
  await step2();
  await step3();
}

if (import.meta.url === `file://${process.argv[1]}`) {
  console.log("--- awaitCallSafe on a happy path ---");
  await awaitCallSafe();
  console.log("\n--- awaitCallSafe on a failure ---");
  await awaitCallSafe("https://api.example.com/broken", { shouldFail: true });
  console.log("\n--- chainedAsyncFunctions (~3s total) ---");
  await chainedAsyncFunctions();
}
