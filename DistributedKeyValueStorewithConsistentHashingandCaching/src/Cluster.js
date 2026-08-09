// The transparent interface a user talks to.
//
//   * put/get/delete never mention nodes — the Cluster hides sharding.
//   * On each write, the Cluster writes to the R primary+replica nodes
//     that are currently alive.
//   * On each read, the Cluster consults the cache first, then falls
//     through the replicas in order.
//   * addNode() / decommission() rebalance keys between physical
//     shards; consistent hashing guarantees the number of keys that
//     move is O(K / N), not O(K), which is the whole point.
//   * failNode() simulates a crash — no rebalance, no lost writes to
//     the dead node; reads survive via replicas as long as at least
//     one owner is alive.

import { HashRing } from "./HashRing.js";
import { Node }     from "./Node.js";
import { LruCache } from "./LruCache.js";

export class Cluster {
  #ring;
  #nodes;              // Map<nodeId, Node>
  #cache;
  #replicationFactor;

  constructor({ replicationFactor = 2, cacheCapacity = 128, vnodesPerNode = 128 } = {}) {
    this.#ring              = new HashRing({ vnodesPerNode });
    this.#nodes             = new Map();
    this.#cache             = new LruCache(cacheCapacity);
    this.#replicationFactor = replicationFactor;
  }

  // --- introspection ----------------------------------------------------
  get nodeIds()           { return [...this.#nodes.keys()]; }
  get replicationFactor() { return this.#replicationFactor; }
  get cache()             { return this.#cache; }

  nodeStats() {
    return this.nodeIds.map(id => {
      const n = this.#nodes.get(id);
      return { id, alive: n.alive, keyCount: n.size };
    });
  }

  // --- membership -------------------------------------------------------

  // Physically join a new node. Returns { moved }, the number of keys
  // that had to relocate — the "minimal data movement" property.
  addNode(nodeId) {
    if (this.#nodes.has(nodeId)) throw new Error(`node ${nodeId} already exists`);
    this.#nodes.set(nodeId, new Node(nodeId));
    this.#ring.addNode(nodeId);
    const moved = this.#rebalance();
    this.#cache.clear();          // ownership changed — safer to invalidate
    return { moved };
  }

  // Graceful removal: rebalances first, then drops the node.
  decommission(nodeId) {
    if (!this.#nodes.has(nodeId)) throw new Error(`unknown node ${nodeId}`);
    // Extract this node's keys before removing it from the ring.
    const departing = this.#nodes.get(nodeId);
    const departingKeys = new Map();
    for (const k of departing.keys()) departingKeys.set(k, departing.get(k));

    this.#ring.removeNode(nodeId);
    this.#nodes.delete(nodeId);

    // Re-place the departing keys onto their new owners.
    let moved = 0;
    for (const [k, v] of departingKeys) {
      for (const targetId of this.#ring.getNodes(k, this.#replicationFactor)) {
        const target = this.#nodes.get(targetId);
        if (target?.alive) { target.put(k, v); moved += 1; }
      }
    }
    // Ensure every remaining key is still on the right replicas.
    moved += this.#rebalance();
    this.#cache.clear();
    return { moved };
  }

  // Simulate a crash — no rebalance, no data ejected. The dead node's
  // keys become temporarily unreadable except via replicas.
  failNode(nodeId) {
    const node = this.#nodes.get(nodeId);
    if (!node) throw new Error(`unknown node ${nodeId}`);
    node.fail();
    this.#cache.clear();           // avoid stale hits masking failure
  }

  recoverNode(nodeId) {
    const node = this.#nodes.get(nodeId);
    if (!node) throw new Error(`unknown node ${nodeId}`);
    node.recover();
  }

  // --- data path --------------------------------------------------------

  put(key, value) {
    const owners = this.#ring.getNodes(key, this.#replicationFactor);
    let writes = 0;
    for (const id of owners) {
      const node = this.#nodes.get(id);
      if (node?.alive) { node.put(key, value); writes += 1; }
    }
    if (writes === 0) throw new Error(`no live replicas for key '${key}'`);
    this.#cache.set(key, value);
    return { writes, owners };
  }

  get(key) {
    const cached = this.#cache.get(key);
    if (cached !== null) return { value: cached, source: "cache" };

    const owners = this.#ring.getNodes(key, this.#replicationFactor);
    for (const id of owners) {
      const node = this.#nodes.get(id);
      if (!node?.alive) continue;
      const value = node.get(key);
      if (value !== null) {
        this.#cache.set(key, value);
        return { value, source: `node:${id}` };
      }
    }
    return { value: null, source: "unavailable" };
  }

  delete(key) {
    const owners = this.#ring.getNodes(key, this.#replicationFactor);
    let deleted = 0;
    for (const id of owners) {
      const node = this.#nodes.get(id);
      if (node?.alive && node.get(key) !== null) { node.delete(key); deleted += 1; }
    }
    this.#cache.invalidate(key);
    return { deleted };
  }

  // --- helpers ----------------------------------------------------------

  // Which nodes currently own each key according to the ring.
  ownershipMap() {
    const map = new Map();
    for (const node of this.#nodes.values()) {
      for (const k of node.keys()) {
        if (!map.has(k)) map.set(k, this.#ring.getNodes(k, this.#replicationFactor));
      }
    }
    return map;
  }

  // Walk every physical key on every LIVE node; make sure it lives on
  // exactly the current owner set. Returns the number of key/node
  // (place-or-remove) operations performed.
  #rebalance() {
    let ops = 0;
    // Snapshot to avoid mutating during iteration.
    const allKeyLocations = new Map();   // key -> Map<nodeId, value>
    for (const node of this.#nodes.values()) {
      if (!node.alive) continue;
      for (const k of node.keys()) {
        if (!allKeyLocations.has(k)) allKeyLocations.set(k, new Map());
        allKeyLocations.get(k).set(node.id, node.get(k));
      }
    }

    for (const [key, locations] of allKeyLocations) {
      const shouldOwn = this.#ring.getNodes(key, this.#replicationFactor);
      const value = locations.values().next().value;

      // Place on any missing owner.
      for (const ownerId of shouldOwn) {
        if (!locations.has(ownerId)) {
          const owner = this.#nodes.get(ownerId);
          if (owner?.alive) { owner.put(key, value); ops += 1; }
        }
      }
      // Remove from any stale holder.
      for (const holderId of locations.keys()) {
        if (!shouldOwn.includes(holderId)) {
          const holder = this.#nodes.get(holderId);
          if (holder?.alive) { holder._internalDelete(key); ops += 1; }
        }
      }
    }
    return ops;
  }
}
