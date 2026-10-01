import type { Request, Response } from 'express';
import { createClinicSchema, updateClinicSchema } from './clinics.schemas.js';
import type { ClinicsService } from './clinics.service.js';

export class ClinicsController {
  constructor(private readonly service: ClinicsService) {}

  list = async (_req: Request, res: Response) => {
    res.json({ data: await this.service.list() });
  };

  create = async (req: Request, res: Response) => {
    res.status(201).json({ data: await this.service.create(createClinicSchema.parse(req.body)) });
  };

  update = async (req: Request<{ id: string }>, res: Response) => {
    res.json({ data: await this.service.update(req.params.id, updateClinicSchema.parse(req.body)) });
  };
}
