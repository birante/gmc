export type Role = 'ADMIN' | 'CLINICIAN';
export type DoseStatus = 'ADMINISTERED' | 'OVERDUE' | 'DUE' | 'UPCOMING';

export interface User {
  id: string;
  email: string;
  name: string;
  role: Role;
  active: boolean;
  clinicId: string | null;
  clinic?: { id: string; name: string; code: string } | null;
}

export interface Clinic {
  id: string;
  code: string;
  name: string;
  region: string;
  district: string;
  _count?: { patients: number; users: number };
}

export interface PatientSummary {
  id: string;
  referenceCode: string;
  firstName: string;
  lastName: string;
  sex: 'F' | 'M';
  dateOfBirth: string;
  guardianName: string;
  guardianPhone: string;
  clinic: { id: string; name: string };
}

export interface Dose {
  id: string;
  vaccine: { id: string; code: string; name: string; antigen: string; doseNumber: number };
  scheduledDate: string;
  administeredDate: string | null;
  administeredBy: { id: string; name: string } | null;
  lotNumber: string | null;
  notes: string | null;
  status: DoseStatus;
}

export interface PatientDetail extends Omit<PatientSummary, 'clinic'> {
  address: string | null;
  age: string;
  clinic: { id: string; name: string; code: string; region: string; district: string };
  summary: { total: number; administered: number; overdue: number; due: number };
  immunizations: Dose[];
}

export interface CoverageRow {
  vaccine: { id: string; code: string; name: string; antigen: string };
  eligible: number;
  administered: number;
  coverage: number;
}

export interface DashboardStats {
  totals: { patients: number; administeredTotal: number; administeredLast30Days: number; dueThisWeek: number; overdue: number };
  indicators: { penta1To3Dropout: number; penta3Coverage: number; mr1Coverage: number };
  coverage: CoverageRow[];
  monthly: Array<{ month: string; count: number }>;
}

export interface WorklistItem {
  id: string;
  scheduledDate: string;
  daysFromToday: number;
  status: DoseStatus;
  vaccine: { id: string; code: string; name: string };
  patient: { id: string; referenceCode: string; firstName: string; lastName: string; guardianName: string; guardianPhone: string; clinic: { name: string } };
  reminderSentAt: string | null;
}

export interface ReminderMessage {
  patientId: string;
  to: string;
  message: string;
  immunizationIds: string[];
}

export interface PublicLookup {
  referenceCode: string;
  child: string;
  age: string;
  clinic: { name: string; district: string };
  nextDose: { code: string; name: string; scheduledDate: string; status: DoseStatus } | null;
  doses: Array<{ code: string; name: string; scheduledDate: string; administeredDate: string | null; status: DoseStatus }>;
}

export interface Paginated<T> {
  data: T[];
  meta: { page: number; pageSize: number; total: number; totalPages: number };
}
