import type { Request, Response } from 'express';
import type { UsersService } from './users.service.js';
import { createUserSchema, updateUserSchema } from './users.schemas.js';

export class UsersController {
  constructor(private readonly service: UsersService) {}

  list = async (_req: Request, res: Response) => {
    res.json({ data: await this.service.list() });
  };

  create = async (req: Request, res: Response) => {
    const user = await this.service.create(createUserSchema.parse(req.body));
    res.status(201).json({ data: user });
  };

  update = async (req: Request<{ id: string }>, res: Response) => {
    res.json({ data: await this.service.update(req.params.id, updateUserSchema.parse(req.body)) });
  };
}
