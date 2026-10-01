import type { Request, Response } from 'express';
import { currentUser } from '../../middleware/auth.js';
import { loginSchema } from './auth.schemas.js';
import type { AuthService } from './auth.service.js';

export class AuthController {
  constructor(private readonly service: AuthService) {}

  login = async (req: Request, res: Response) => {
    res.json({ data: await this.service.login(loginSchema.parse(req.body)) });
  };

  me = async (req: Request, res: Response) => {
    res.json({ data: await this.service.me(currentUser(req).id) });
  };
}
