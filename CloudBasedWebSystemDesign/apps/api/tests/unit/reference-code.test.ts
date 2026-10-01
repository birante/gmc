import { describe, expect, it } from 'vitest';
import { generateReferenceCode, maskPhone, normalizePhone } from '../../src/domain/reference-code.js';

describe('reference codes', () => {
  it('generates readable codes without ambiguous characters', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateReferenceCode();
      expect(code).toMatch(/^VX-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$/);
    }
  });

  it('is practically unique', () => {
    const codes = new Set(Array.from({ length: 1000 }, generateReferenceCode));
    expect(codes.size).toBe(1000);
  });
});

describe('phone helpers', () => {
  it('normalises spaces and dashes', () => {
    expect(normalizePhone('+221 77 000-45 67')).toBe('+221770004567');
  });

  it('masks all but the last four digits', () => {
    const masked = maskPhone('+221770004567');
    expect(masked.endsWith('4567')).toBe(true);
    expect(masked).toContain('*');
    expect(masked).not.toContain('77000');
  });
});
