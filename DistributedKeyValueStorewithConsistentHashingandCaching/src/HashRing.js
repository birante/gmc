// Consistent hash ring.
//
// A ring of 2^32 positions. Each physical node stakes V "virtual nodes"
// (VNodes) spread across the ring, which flattens the load per physical
// node even when only a few of them are up. To find the owner of a key
// we hash the key, walk the ring clockwise, and pick the first VNode
// whose hash is >= the key's hash. Replicas are the next R-1 distinct
// physical nodes we encounter after the primary.

import { createHash } from "node:crypto";

// Deterministic 32-bit unsigned hash from SHA-1 (first 4 bytes big-endian).
function hash32(str) {
  return createHash("sha1").update(String(str)).digest().readUInt32BE(0);
}

// Binary-search the smallest index whose h >= target; wraps to 0 at the top.
function lowerBound(sorted, target) {
  let lo = 0, hi = sorted.length;
  while (lo < hi) {
    const mid = (lo + hi) >>> 1;
    if (sorted[mid].h < target) lo = mid + 1;
    else hi = mid;
  }
  return lo === sorted.length ? 0 : lo;
}

export class HashRing {
  #vnodesPerNode;
  #ring;      // sorted array of { h: uint32, nodeId: string }
  #nodes;     // Set<string>

  constructor({ vnodesPerNode = 128 } = {}) {
    this.#vnodesPerNode = vnodesPerNode;
    this.#ring = [];
    this.#nodes = new Set();
  }

  get nodes()          { return [...this.#nodes]; }
  get size()           { return this.#nodes.size; }
  get ringLength()     { return this.#ring.length; }
  get vnodesPerNode()  { return this.#vnodesPerNode; }

  addNode(nodeId) {
    if (this.#nodes.has(nodeId)) return;
    this.#nodes.add(nodeId);
    for (let i = 0; i < this.#vnodesPerNode; i += 1) {
      this.#ring.push({ h: hash32(`${nodeId}#${i}`), nodeId });
    }
    this.#ring.sort((a, b) => a.h - b.h);
  }

  removeNode(nodeId) {
    if (!this.#nodes.has(nodeId)) return;
    this.#nodes.delete(nodeId);
    this.#ring = this.#ring.filter(v => v.nodeId !== nodeId);
  }

  // Primary node for a key, or null if the ring is empty.
  getNode(key) {
    if (this.#ring.length === 0) return null;
    const idx = lowerBound(this.#ring, hash32(key));
    return this.#ring[idx].nodeId;
  }

  // The R distinct physical nodes responsible for a key, in preference
  // order (primary, then successors on the ring).
  getNodes(key, replicationFactor) {
    if (this.#ring.length === 0) return [];
    const r = Math.min(replicationFactor, this.#nodes.size);
    const start = lowerBound(this.#ring, hash32(key));
    const owners = [];
    for (let i = 0; i < this.#ring.length && owners.length < r; i += 1) {
      const nodeId = this.#ring[(start + i) % this.#ring.length].nodeId;
      if (!owners.includes(nodeId)) owners.push(nodeId);
    }
    return owners;
  }

  // Debug helper — histogram of key ownership over a sample of keys.
  distribution(sampleKeys) {
    const counts = new Map(this.nodes.map(n => [n, 0]));
    for (const k of sampleKeys) {
      const owner = this.getNode(k);
      if (owner) counts.set(owner, (counts.get(owner) ?? 0) + 1);
    }
    return counts;
  }
}
