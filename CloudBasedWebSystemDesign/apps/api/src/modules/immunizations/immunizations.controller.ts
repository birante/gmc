import type { Request, Response } from 'express';
import { currentUser } from '../../middleware/auth.js';
import { administerSchema, worklistSchema } from './immunizations.schemas.js';
import type { ImmunizationsService } from './immunizations.service.js';

export class ImmunizationsController {
  constructor(private readonly service: ImmunizationsService) {}

  administer = async (req: Request<{ id: string }>, res: Response) => {
    const body = administerSchema.parse(req.body ?? {});
    res.json({ data: await this.service.administer(currentUser(req), req.params.id, body) });
  };

  revert = async (req: Request<{ id: string }>, res: Response) => {
    res.json({ data: await this.service.revert(currentUser(req), req.params.id) });
  };

  worklist = async (req: Request, res: Response) => {
    res.json({ data: await this.service.worklist(currentUser(req), worklistSchema.parse(req.query)) });
  };
}
