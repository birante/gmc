// Unit tests. Focused on the invariants that would embarrass the design
// if broken: consistent hashing is deterministic, adding a node moves
// only its fair share, and failover keeps reads working while replicas
// exist.

import { HashRing } from "../src/HashRing.js";
import { Cluster }  from "../src/Cluster.js";
import { LruCache } from "../src/LruCache.js";
import { TtlCache } from "../src/TtlCache.js";

let pass = 0, fail = 0;
async function t(name, fn) {
  try { await fn(); console.log(`  ok   ${name}`); pass += 1; }
  catch (e) { console.error(`  FAIL ${name}\n       ${e.message}`); fail += 1; }
}
function ok(c, m = "assertion failed") { if (!c) throw new Error(m); }
function eq(a, b, m = "") { if (a !== b) throw new Error(`${m} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`); }

console.log("\n--- distributed-kv-store tests ---");

// -----------------------------------------------------------------------
// HashRing
// -----------------------------------------------------------------------
await t("hash ring: same key always maps to the same node", () => {
  const r = new HashRing();
  ["a","b","c","d"].forEach(id => r.addNode(id));
  eq(r.getNode("user:101"), r.getNode("user:101"));
});

await t("hash ring: replicas returned are distinct physical nodes", () => {
  const r = new HashRing();
  ["a","b","c","d","e"].forEach(id => r.addNode(id));
  const owners = r.getNodes("user:42", 3);
  eq(owners.length, 3);
  eq(new Set(owners).size, 3);
});

await t("hash ring: distribution is reasonably even (128 vnodes, 1000 keys, 4 nodes)", () => {
  const r = new HashRing({ vnodesPerNode: 128 });
  ["a","b","c","d"].forEach(id => r.addNode(id));
  const sample = [];
  for (let i = 0; i < 1000; i += 1) sample.push(`k:${i}`);
  const counts = [...r.distribution(sample).values()];
  const avg = 1000 / 4;
  for (const c of counts) ok(Math.abs(c - avg) < 100, `count ${c} too far from ${avg}`);
});

// -----------------------------------------------------------------------
// LRU cache
// -----------------------------------------------------------------------
await t("LRU: evicts least-recently-used entry", () => {
  const c = new LruCache(2);
  c.set("a", 1); c.set("b", 2);
  c.get("a");           // now b is LRU
  c.set("c", 3);        // should evict b
  eq(c.get("a"), 1);
  eq(c.get("b"), null);
  eq(c.get("c"), 3);
});

// -----------------------------------------------------------------------
// TTL cache
// -----------------------------------------------------------------------
await t("TTL: entries expire on read", async () => {
  const c = new TtlCache();
  c.set("k", 42, 30);
  eq(c.get("k"), 42);
  await new Promise(r => setTimeout(r, 60));
  eq(c.get("k"), null);
});

// -----------------------------------------------------------------------
// Cluster — end-to-end
// -----------------------------------------------------------------------
const seedUsers = (kv) => {
  kv.put("user:101", { name: "Alice"   });
  kv.put("user:102", { name: "Bob"     });
  kv.put("user:103", { name: "Charlie" });
  kv.put("user:104", { name: "Diana"   });
  kv.put("user:105", { name: "Eve"     });
  kv.put("user:106", { name: "Frank"   });
};

await t("Cluster: get returns the value we put (transparency)", () => {
  const kv = new Cluster({ replicationFactor: 2 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  seedUsers(kv);
  const { value } = kv.get("user:104");
  eq(value?.name, "Diana");
});

await t("Cluster: cache serves the second read", () => {
  const kv = new Cluster({ replicationFactor: 2, cacheCapacity: 10 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  seedUsers(kv);
  eq(kv.get("user:101").source, "cache");   // put warms the cache
  const before = kv.cache.hits;
  kv.get("user:101");
  ok(kv.cache.hits > before, "expected another cache hit");
});

await t("Cluster: adding a node relocates a small fraction of keys (consistent hashing)", () => {
  const kv = new Cluster({ replicationFactor: 1, cacheCapacity: 10, vnodesPerNode: 128 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  for (let i = 0; i < 200; i += 1) kv.put(`k:${i}`, i);
  const { moved } = kv.addNode("d");
  // `moved` counts every place-or-remove op — each relocated key adds 2
  // (one place on the new owner, one delete on the old). Baseline for a
  // 3→4 rebalance with 200 keys is 200/4 = 50 relocated keys = 100 ops.
  // Empirically well under half of the keyspace (< 200 ops = < 100 keys).
  ok(moved < 200, `expected < 200 ops (< 100 keys), got ${moved}`);
});

await t("Cluster: reads survive a single-node failure (rf=2)", () => {
  const kv = new Cluster({ replicationFactor: 2 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  seedUsers(kv);
  kv.failNode("a");
  let reachable = 0;
  for (const k of ["user:101","user:102","user:103","user:104","user:105","user:106"]) {
    if (kv.get(k).source !== "unavailable") reachable += 1;
  }
  eq(reachable, 6, "every key must be reachable via a live replica");
});

await t("Cluster: keys owned only by dead nodes become unavailable", () => {
  const kv = new Cluster({ replicationFactor: 1 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  seedUsers(kv);
  const owners = new Map();
  for (const k of ["user:101","user:102","user:103","user:104","user:105","user:106"]) {
    owners.set(k, kv.get(k));
  }
  kv.failNode("a");
  let unavailable = 0;
  for (const k of ["user:101","user:102","user:103","user:104","user:105","user:106"]) {
    if (kv.get(k).source === "unavailable") unavailable += 1;
  }
  ok(unavailable > 0, "with rf=1 and one node down, at least one key must be lost");
});

await t("Cluster: decommission preserves data across the surviving nodes", () => {
  const kv = new Cluster({ replicationFactor: 2 });
  ["a","b","c"].forEach(id => kv.addNode(id));
  seedUsers(kv);
  kv.decommission("b");
  for (const k of ["user:101","user:102","user:103","user:104","user:105","user:106"]) {
    ok(kv.get(k).value !== null, `${k} lost after decommission`);
  }
});

console.log(`\n${pass} passed, ${fail} failed.`);
if (fail > 0) process.exit(1);
