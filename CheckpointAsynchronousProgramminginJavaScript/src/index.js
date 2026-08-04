// Runs every task back-to-back with a divider between them.
// Total wall-clock: ~8 seconds (3 s iterate + 0.5 s awaitCall +
// 0.5 s awaitCallSafe + 0.5 s awaitCallSafe error + 3 s chained + 0.5 s
// concurrent + 0.5 s parallel + 0.5 s parallelSettled).

import { iterateWithAsyncAwait }        from "./task01.js";
import { awaitCall }                    from "./task02.js";
import { awaitCallSafe, chainedAsyncFunctions } from "./task03.js";
import { concurrentRequests }           from "./task04.js";
import { parallelCalls, parallelCallsSettled } from "./task05.js";

const line = (title) => console.log(`\n=== ${title} ===`);

line("Task 01 — iterateWithAsyncAwait (~3s)");
await iterateWithAsyncAwait(["Apple", "Banana", "Cherry"]);

line("Task 02 — awaitCall");
await awaitCall();

line("Task 03a — awaitCallSafe (happy path)");
await awaitCallSafe();
line("Task 03b — awaitCallSafe (failure)");
await awaitCallSafe("https://api.example.com/broken", { shouldFail: true });
line("Task 03c — chainedAsyncFunctions (~3s)");
await chainedAsyncFunctions();

line("Task 04 — concurrentRequests");
await concurrentRequests();

line("Task 05a — parallelCalls");
await parallelCalls([
  "https://api.example.com/users",
  "https://api.example.com/posts",
  "https://api.example.com/comments",
]);

line("Task 05b — parallelCallsSettled (one of three fails)");
await parallelCallsSettled(
  ["https://api.example.com/a", "https://api.example.com/b", "https://api.example.com/c"],
  [1],
);
