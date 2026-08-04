// Task 04 — Awaiting Concurrent Requests.
//
// Both fetches are STARTED before either is awaited, so their delays
// overlap. Compared to awaiting them one at a time, this cuts the total
// wall-clock roughly in half (both fake calls take ~500 ms, so
// concurrent total ≈ 500 ms; sequential would be ≈ 1000 ms).

import { fakeFetch } from "./utils.js";

export async function concurrentRequests() {
  const t0 = Date.now();
  const [users, posts] = await Promise.all([
    fakeFetch("https://api.example.com/users"),
    fakeFetch("https://api.example.com/posts"),
  ]);
  const elapsed = Date.now() - t0;
  console.log(`[concurrentRequests] both resolved in ~${elapsed} ms`);
  console.log("[concurrentRequests] combined:", {
    users: users.data,
    posts: posts.data,
  });
  return { users: users.data, posts: posts.data };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  await concurrentRequests();
}
