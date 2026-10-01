import { forbidden } from '../lib/errors.js';
import type { AuthUser } from '../lib/jwt.js';

/**
 * Multi-tenant scoping rule used by every clinic-owned resource:
 *  - ADMIN sees everything, or a single clinic if `requestedClinicId` is given;
 *  - CLINICIAN only ever sees their own clinic.
 * Returns the clinic id to filter by, or `undefined` for "all clinics".
 */
export function resolveClinicScope(user: AuthUser, requestedClinicId?: string): string | undefined {
  if (user.role === 'ADMIN') return requestedClinicId || undefined;
  if (!user.clinicId) throw forbidden('Your account is not attached to a clinic');
  if (requestedClinicId && requestedClinicId !== user.clinicId) throw forbidden();
  return user.clinicId;
}

export function assertClinicAccess(user: AuthUser, clinicId: string): void {
  if (user.role === 'ADMIN') return;
  if (user.clinicId !== clinicId) throw forbidden();
}
