import type { PrismaClient } from '@prisma/client';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';
import { AuthController } from './modules/auth/auth.controller.js';
import { AuthService } from './modules/auth/auth.service.js';
import { ClinicsController } from './modules/clinics/clinics.controller.js';
import { ClinicsRepository } from './modules/clinics/clinics.repository.js';
import { ClinicsService } from './modules/clinics/clinics.service.js';
import { DashboardRepository } from './modules/dashboard/dashboard.repository.js';
import { DashboardService } from './modules/dashboard/dashboard.service.js';
import { ImmunizationsController } from './modules/immunizations/immunizations.controller.js';
import { ImmunizationsRepository } from './modules/immunizations/immunizations.repository.js';
import { ImmunizationsService } from './modules/immunizations/immunizations.service.js';
import { PatientsController } from './modules/patients/patients.controller.js';
import { PatientsRepository } from './modules/patients/patients.repository.js';
import { PatientsService } from './modules/patients/patients.service.js';
import { PublicService } from './modules/public/public.service.js';
import { ConsoleSmsNotifier, type SmsNotifier } from './modules/reminders/notifier.js';
import { RemindersService } from './modules/reminders/reminders.service.js';
import { UsersController } from './modules/users/users.controller.js';
import { UsersRepository } from './modules/users/users.repository.js';
import { UsersService } from './modules/users/users.service.js';
import { VaccinesRepository } from './modules/vaccines/vaccines.repository.js';

export interface ContainerOptions {
  db: PrismaClient;
  notifier?: SmsNotifier;
}

/**
 * Composition root: wires repositories -> services -> controllers.
 * Swapping an adapter (e.g. the SMS provider) only requires a change here.
 */
export function createContainer({ db, notifier }: ContainerOptions) {
  const repos = {
    users: new UsersRepository(db),
    clinics: new ClinicsRepository(db),
    vaccines: new VaccinesRepository(db),
    patients: new PatientsRepository(db),
    immunizations: new ImmunizationsRepository(db),
    dashboard: new DashboardRepository(db),
  };
  const sms = notifier ?? new ConsoleSmsNotifier(logger);

  const services = {
    auth: new AuthService(repos.users),
    users: new UsersService(repos.users),
    clinics: new ClinicsService(repos.clinics),
    patients: new PatientsService(repos.patients, repos.vaccines, repos.clinics),
    immunizations: new ImmunizationsService(repos.immunizations),
    dashboard: new DashboardService(repos.dashboard),
    reminders: new RemindersService(repos.immunizations, sms, env.REMINDER_WINDOW_DAYS),
    public: new PublicService(repos.patients),
  };

  const controllers = {
    auth: new AuthController(services.auth),
    users: new UsersController(services.users),
    clinics: new ClinicsController(services.clinics),
    patients: new PatientsController(services.patients),
    immunizations: new ImmunizationsController(services.immunizations),
  };

  return { db, repos, services, controllers };
}

export type Container = ReturnType<typeof createContainer>;
