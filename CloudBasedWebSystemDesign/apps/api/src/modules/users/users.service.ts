import bcrypt from 'bcryptjs';
import { badRequest, conflict, notFound } from '../../lib/errors.js';
import type { UsersRepository } from './users.repository.js';
import type { CreateUserInput, UpdateUserInput } from './users.schemas.js';

export const BCRYPT_ROUNDS = 10;

export class UsersService {
  constructor(private readonly users: UsersRepository) {}

  list() {
    return this.users.list();
  }

  async getById(id: string) {
    const user = await this.users.findById(id);
    if (!user) throw notFound('User');
    return user;
  }

  async create(input: CreateUserInput) {
    if (input.role === 'CLINICIAN' && !input.clinicId) throw badRequest('A clinician must be attached to a clinic');
    if (await this.users.findByEmail(input.email)) throw conflict('Email is already registered');
    const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);
    return this.users.create({
      email: input.email,
      name: input.name,
      role: input.role,
      clinicId: input.clinicId ?? null,
      passwordHash,
    });
  }

  async update(id: string, input: UpdateUserInput) {
    await this.getById(id);
    const { password, ...rest } = input;
    const data = password ? { ...rest, passwordHash: await bcrypt.hash(password, BCRYPT_ROUNDS) } : rest;
    return this.users.update(id, data);
  }
}
