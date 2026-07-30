// Generic in-memory implementation of the Repository interface.
// Backed by a Map<id, entity>. One instance per aggregate type.

import { Repository } from "../interfaces/Repository.js";

export class InMemoryRepository extends Repository {
  #store;

  constructor() {
    super();
    this.#store = new Map();
  }

  save(entity) {
    if (!entity?.id) throw new Error("Cannot save entity without an id.");
    this.#store.set(entity.id, entity);
    return entity;
  }

  findById(id) {
    return this.#store.get(id) ?? null;
  }

  findAll() {
    return [...this.#store.values()];
  }

  delete(id) {
    return this.#store.delete(id);
  }
}
