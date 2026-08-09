// End-to-end demo — walks through every requirement in the brief.

import { Cluster } from "./Cluster.js";
import { TtlCache } from "./TtlCache.js";

const line = (title) => console.log(`\n===== ${title} =====`);
const sub  = (title) => console.log(`\n--- ${title} ---`);

// -----------------------------------------------------------------------
// 1) Build the cluster: 3 nodes, replication factor 2, 128 vnodes each.
// -----------------------------------------------------------------------
line("1) Build a 3-node cluster (replication factor = 2)");
const kv = new Cluster({ replicationFactor: 2, cacheCapacity: 64, vnodesPerNode: 128 });
for (const id of ["node-A", "node-B", "node-C"]) kv.addNode(id);
console.log("nodes:", kv.nodeIds);

// -----------------------------------------------------------------------
// 2) Insert the six users from the brief.
// -----------------------------------------------------------------------
line("2) PUT six users");
const USERS = {
  "user:101": { name: "Alice"   },
  "user:102": { name: "Bob"     },
  "user:103": { name: "Charlie" },
  "user:104": { name: "Diana"   },
  "user:105": { name: "Eve"     },
  "user:106": { name: "Frank"   },
};
for (const [key, value] of Object.entries(USERS)) {
  const { writes, owners } = kv.put(key, value);
  console.log(`  put ${key} -> ${writes} replica(s) on [${owners.join(", ")}]`);
}

// -----------------------------------------------------------------------
// 3) Show cache miss then hit — transparency of "where does data live?"
// -----------------------------------------------------------------------
line("3) GET each user (first pass = misses, second = cache hits)");
kv.cache.clear();   // put() warms the cache; clear so the first pass shows real node reads
sub("first pass — served by node replicas");
for (const key of Object.keys(USERS)) {
  const { value, source } = kv.get(key);
  console.log(`  get ${key} -> ${JSON.stringify(value)}  [source: ${source}]`);
}
sub("second pass — served by cache");
for (const key of Object.keys(USERS)) {
  const { source } = kv.get(key);
  console.log(`  get ${key} -> [source: ${source}]`);
}
console.log(`\ncache stats: hits=${kv.cache.hits} misses=${kv.cache.misses}`);

// -----------------------------------------------------------------------
// 4) Add a 4th node — observe minimal data movement.
// -----------------------------------------------------------------------
line("4) Add node-D — minimal data movement");
const beforeStats = kv.nodeStats();
console.log("before:", JSON.stringify(beforeStats));
const addResult = kv.addNode("node-D");
const afterStats  = kv.nodeStats();
console.log("after: ", JSON.stringify(afterStats));
console.log(`rebalance ops: ${addResult.moved} (expect ~= (K * R) / N = ${6 * 2 / 4} baseline)`);

// -----------------------------------------------------------------------
// 5) Simulate a node failure — replicas keep the system responsive.
// -----------------------------------------------------------------------
line("5) Fail node-A — reads should still succeed via replicas");
kv.failNode("node-A");
let reachable = 0;
for (const key of Object.keys(USERS)) {
  const { source } = kv.get(key);
  if (source !== "unavailable") reachable += 1;
}
console.log(`  ${reachable} / 6 users still reachable with node-A dead`);

sub("Now also fail node-B (only C and D left)");
kv.failNode("node-B");
let stillOk = 0, gone = 0;
for (const key of Object.keys(USERS)) {
  const { value, source } = kv.get(key);
  if (source === "unavailable") { console.log(`  ${key} -> UNAVAILABLE`); gone += 1; }
  else                          { console.log(`  ${key} -> ok (via ${source})`); stillOk += 1; }
}
console.log(`\navailability report: ${stillOk} ok, ${gone} lost.`);
console.log("(with rf=2 and vnodes across 4 nodes, 2 failures often still leave a live replica for every key)");

sub("Contrast — rf=1 would lose keys under the same failure");
const kv1 = new Cluster({ replicationFactor: 1, cacheCapacity: 64 });
["a","b","c","d"].forEach(id => kv1.addNode(id));
for (const [k, v] of Object.entries(USERS)) kv1.put(k, v);
kv1.failNode("a"); kv1.failNode("b");
let lost1 = 0;
for (const k of Object.keys(USERS)) if (kv1.get(k).source === "unavailable") lost1 += 1;
console.log(`  rf=1, 2 of 4 nodes down -> ${lost1} of 6 users unavailable (limited availability)`);

// -----------------------------------------------------------------------
// 6) Recover both dead nodes, then decommission node-D gracefully.
// -----------------------------------------------------------------------
line("6) Recover node-A + node-B, then decommission node-D gracefully");
kv.recoverNode("node-A");
kv.recoverNode("node-B");
const decomm = kv.decommission("node-D");
console.log(`decommission moved: ${decomm.moved} operations`);
console.log("nodes now:", kv.nodeIds);
console.log("stats:", JSON.stringify(kv.nodeStats()));

sub("Verify every user is reachable again");
for (const key of Object.keys(USERS)) {
  const { source } = kv.get(key);
  console.log(`  get ${key} -> [source: ${source}]`);
}

// -----------------------------------------------------------------------
// 7) Bonus — TTL cache in front of the cluster.
// -----------------------------------------------------------------------
line("7) TTL cache demo");
const ttl = new TtlCache();
ttl.set("user:101", USERS["user:101"], 50);   // 50 ms
console.log(`ttl.get('user:101') immediate -> ${JSON.stringify(ttl.get("user:101"))}`);
await new Promise(r => setTimeout(r, 120));
console.log(`ttl.get('user:101') after 120ms -> ${JSON.stringify(ttl.get("user:101"))}`);
console.log(`ttl stats: hits=${ttl.hits} misses=${ttl.misses}`);
