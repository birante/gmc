import { notFound } from '../../lib/errors.js';
import type { ClinicsRepository } from './clinics.repository.js';
import type { CreateClinicInput, UpdateClinicInput } from './clinics.schemas.js';

export class ClinicsService {
  constructor(private readonly clinics: ClinicsRepository) {}

  list() {
    return this.clinics.list();
  }

  create(input: CreateClinicInput) {
    return this.clinics.create(input);
  }

  async update(id: string, input: UpdateClinicInput) {
    if (!(await this.clinics.findById(id))) throw notFound('Clinic');
    return this.clinics.update(id, input);
  }
}
