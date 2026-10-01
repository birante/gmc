import { describe, expect, it } from 'vitest';
import { AppError } from '../../src/lib/errors.js';
import { signToken, verifyToken } from '../../src/lib/jwt.js';
import { assertClinicAccess, resolveClinicScope } from '../../src/middleware/access.js';

const admin = { id: 'a', role: 'ADMIN' as const, clinicId: null };
const nurse = { id: 'n', role: 'CLINICIAN' as const, clinicId: 'clinic-1' };

describe('resolveClinicScope', () => {
  it('lets admins see all clinics or filter one', () => {
    expect(resolveClinicScope(admin)).toBeUndefined();
    expect(resolveClinicScope(admin, 'clinic-2')).toBe('clinic-2');
  });

  it('pins clinicians to their own clinic', () => {
    expect(resolveClinicScope(nurse)).toBe('clinic-1');
    expect(resolveClinicScope(nurse, 'clinic-1')).toBe('clinic-1');
  });

  it('forbids clinicians from reading another clinic', () => {
    expect(() => resolveClinicScope(nurse, 'clinic-2')).toThrowError(AppError);
    expect(() => assertClinicAccess(nurse, 'clinic-2')).toThrowError(/access/);
    expect(() => assertClinicAccess(admin, 'clinic-2')).not.toThrow();
  });

  it('forbids clinicians that are not attached to a clinic', () => {
    expect(() => resolveClinicScope({ ...nurse, clinicId: null })).toThrowError(/not attached/);
  });
});

describe('JWT', () => {
  it('round-trips the user identity', () => {
    expect(verifyToken(signToken(nurse))).toEqual(nurse);
  });

  it('rejects tampered tokens', () => {
    const token = signToken(nurse);
    expect(() => verifyToken(`${token.slice(0, -2)}xx`)).toThrow();
  });
});
