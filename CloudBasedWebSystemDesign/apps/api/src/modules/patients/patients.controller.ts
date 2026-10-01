import type { Request, Response } from 'express';
import { currentUser } from '../../middleware/auth.js';
import { createPatientSchema, listPatientsSchema, updatePatientSchema } from './patients.schemas.js';
import type { PatientsService } from './patients.service.js';

export class PatientsController {
  constructor(private readonly service: PatientsService) {}

  list = async (req: Request, res: Response) => {
    res.json(await this.service.list(currentUser(req), listPatientsSchema.parse(req.query)));
  };

  get = async (req: Request<{ id: string }>, res: Response) => {
    res.json({ data: await this.service.getById(currentUser(req), req.params.id) });
  };

  create = async (req: Request, res: Response) => {
    const patient = await this.service.create(currentUser(req), createPatientSchema.parse(req.body));
    res.status(201).location(`/api/patients/${patient.id}`).json({ data: patient });
  };

  update = async (req: Request<{ id: string }>, res: Response) => {
    const body = updatePatientSchema.parse(req.body);
    res.json({ data: await this.service.update(currentUser(req), req.params.id, body) });
  };

  remove = async (req: Request<{ id: string }>, res: Response) => {
    await this.service.remove(currentUser(req), req.params.id);
    res.status(204).end();
  };
}
