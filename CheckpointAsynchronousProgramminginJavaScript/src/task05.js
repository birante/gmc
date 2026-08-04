// Task 05 — Awaiting Parallel Calls.
//
// Same idea as Task 4, generalised to any number of URLs. `map` produces
// an array of pending promises (each fakeFetch is started immediately
// because it is called synchronously inside .map); Promise.all lets us
// await the whole batch as one.
//
// Note on failure behaviour: Promise.all rejects at the first failure and
// throws away the others' results. For a best-effort variant that
// tolerates individual failures, `Promise.allSettled` is a drop-in
// replacement — see the second demo below.

import { fakeFetch } from "./utils.js";

export async function parallelCalls(urls) {
  const responses = await Promise.all(urls.map(url => fakeFetch(url)));
  console.log(`[parallelCalls] ${responses.length} response(s) received:`);
  for (const r of responses) console.log(`  ${r.url} -> ${r.data.message}`);
  return responses;
}

// Bonus — same shape but keeps going through failures.
export async function parallelCallsSettled(urls, failIndices = []) {
  const results = await Promise.allSettled(
    urls.map((url, i) => fakeFetch(url, { shouldFail: failIndices.includes(i) }))
  );
  const ok  = results.filter(r => r.status === "fulfilled").map(r => r.value);
  const err = results.filter(r => r.status === "rejected").map(r => r.reason.message);
  console.log(`[parallelCallsSettled] ${ok.length} ok, ${err.length} failed.`);
  if (err.length) console.log("  failures:", err);
  return { ok, err };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  await parallelCalls([
    "https://api.example.com/1",
    "https://api.example.com/2",
    "https://api.example.com/3",
  ]);
  console.log();
  await parallelCallsSettled(
    ["https://api.example.com/a", "https://api.example.com/b", "https://api.example.com/c"],
    [1]   // the middle one fails
  );
}
