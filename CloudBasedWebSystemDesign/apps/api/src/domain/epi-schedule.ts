/**
 * Default routine childhood immunisation schedule used to seed the database.
 *
 * It follows the WHO-recommended EPI structure (birth, 6, 10 and 14 weeks,
 * 9 and 15 months) as commonly implemented in Senegal's Programme Elargi de
 * Vaccination (PEV). The schedule is DATA, not code: administrators must
 * validate it against the current Ministry of Health guidance and can adjust
 * it in the `Vaccine` table without a redeploy.
 */
export interface ScheduleEntry {
  code: string;
  antigen: string;
  name: string;
  doseNumber: number;
  recommendedAgeDays: number;
  description?: string;
}

const WEEK = 7;
const MONTH = 30; // EPI ages in months are approximated to 30 days for scheduling.

export const DEFAULT_EPI_SCHEDULE: ScheduleEntry[] = [
  { code: 'BCG', antigen: 'BCG', name: 'BCG (tuberculosis)', doseNumber: 1, recommendedAgeDays: 0 },
  { code: 'OPV-0', antigen: 'OPV', name: 'Oral polio vaccine - birth dose', doseNumber: 0, recommendedAgeDays: 0 },
  { code: 'HEPB-0', antigen: 'HepB', name: 'Hepatitis B - birth dose', doseNumber: 0, recommendedAgeDays: 0 },

  { code: 'PENTA-1', antigen: 'Penta', name: 'Pentavalent (DTP-HepB-Hib) 1', doseNumber: 1, recommendedAgeDays: 6 * WEEK },
  { code: 'OPV-1', antigen: 'OPV', name: 'Oral polio vaccine 1', doseNumber: 1, recommendedAgeDays: 6 * WEEK },
  { code: 'PCV-1', antigen: 'PCV', name: 'Pneumococcal conjugate 1', doseNumber: 1, recommendedAgeDays: 6 * WEEK },
  { code: 'ROTA-1', antigen: 'Rota', name: 'Rotavirus 1', doseNumber: 1, recommendedAgeDays: 6 * WEEK },

  { code: 'PENTA-2', antigen: 'Penta', name: 'Pentavalent (DTP-HepB-Hib) 2', doseNumber: 2, recommendedAgeDays: 10 * WEEK },
  { code: 'OPV-2', antigen: 'OPV', name: 'Oral polio vaccine 2', doseNumber: 2, recommendedAgeDays: 10 * WEEK },
  { code: 'PCV-2', antigen: 'PCV', name: 'Pneumococcal conjugate 2', doseNumber: 2, recommendedAgeDays: 10 * WEEK },
  { code: 'ROTA-2', antigen: 'Rota', name: 'Rotavirus 2', doseNumber: 2, recommendedAgeDays: 10 * WEEK },

  { code: 'PENTA-3', antigen: 'Penta', name: 'Pentavalent (DTP-HepB-Hib) 3', doseNumber: 3, recommendedAgeDays: 14 * WEEK },
  { code: 'OPV-3', antigen: 'OPV', name: 'Oral polio vaccine 3', doseNumber: 3, recommendedAgeDays: 14 * WEEK },
  { code: 'PCV-3', antigen: 'PCV', name: 'Pneumococcal conjugate 3', doseNumber: 3, recommendedAgeDays: 14 * WEEK },
  { code: 'IPV-1', antigen: 'IPV', name: 'Inactivated polio vaccine 1', doseNumber: 1, recommendedAgeDays: 14 * WEEK },

  { code: 'MR-1', antigen: 'MR', name: 'Measles-Rubella 1', doseNumber: 1, recommendedAgeDays: 9 * MONTH },
  { code: 'YF', antigen: 'YF', name: 'Yellow fever', doseNumber: 1, recommendedAgeDays: 9 * MONTH },

  { code: 'MR-2', antigen: 'MR', name: 'Measles-Rubella 2', doseNumber: 2, recommendedAgeDays: 15 * MONTH },
];
