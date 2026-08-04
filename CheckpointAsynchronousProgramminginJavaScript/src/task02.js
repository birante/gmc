// Task 02 — Awaiting a Call.
//
// The async function suspends at `await fakeFetch(...)` until the
// promise settles, then continues on the next line. Reads like sync
// code even though nothing else on the event loop is blocked.

import { fakeFetch } from "./utils.js";

export async function awaitCall(url = "https://api.example.com/todo/1") {
  const response = await fakeFetch(url);
  console.log("[awaitCall] data received:", response.data);
  return response.data;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  await awaitCall();
}
