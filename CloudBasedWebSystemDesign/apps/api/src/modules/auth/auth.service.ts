import bcrypt from 'bcryptjs';
import { unauthorized } from '../../lib/errors.js';
import { signToken } from '../../lib/jwt.js';
import type { UsersRepository } from '../users/users.repository.js';
import type { LoginInput } from './auth.schemas.js';

// Pre-computed hash used to keep response time constant when the email is unknown
// (mitigates user enumeration through timing).
const DUMMY_HASH = bcrypt.hashSync('vaxtrack-timing-dummy', 10);

export class AuthService {
  constructor(private readonly users: UsersRepository) {}

  async login({ email, password }: LoginInput) {
    const user = await this.users.findByEmail(email);
    const valid = await bcrypt.compare(password, user?.passwordHash ?? DUMMY_HASH);
    if (!user || !valid || !user.active) throw unauthorized('Invalid email or password');

    const token = signToken({ id: user.id, role: user.role, clinicId: user.clinicId });
    const profile = await this.users.findById(user.id);
    return { token, user: profile };
  }

  async me(userId: string) {
    const user = await this.users.findById(userId);
    if (!user || !user.active) throw unauthorized();
    return user;
  }
}
