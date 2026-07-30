// Interface-like base class for persistence. Concrete repositories must
// implement every method; the base throws to catch missing implementations.

export class Repository {
  save(entity)    { throw new Error("Repository.save(entity) not implemented"); }
  findById(id)    { throw new Error("Repository.findById(id) not implemented"); }
  findAll()       { throw new Error("Repository.findAll() not implemented"); }
  delete(id)      { throw new Error("Repository.delete(id) not implemented"); }
}
