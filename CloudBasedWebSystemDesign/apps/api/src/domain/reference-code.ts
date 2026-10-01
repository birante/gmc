import { randomInt } from 'node:crypto';

// No 0/O/1/I to avoid confusion when read aloud or written on a paper card.
const ALPHABET = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

/** Generates a human-friendly card number such as "VX-7KQ9-M2TD". */
export function generateReferenceCode(): string {
  const part = () => Array.from({ length: 4 }, () => ALPHABET[randomInt(ALPHABET.length)]).join('');
  return `VX-${part()}-${part()}`;
}

export function normalizePhone(phone: string): string {
  return phone.replace(/[^\d+]/g, '');
}

/** Masks a phone number for display in public responses: +221*****4567. */
export function maskPhone(phone: string): string {
  const digits = normalizePhone(phone);
  if (digits.length <= 4) return '****';
  return `${digits.slice(0, Math.min(4, digits.length - 4))}${'*'.repeat(Math.max(digits.length - 8, 2))}${digits.slice(-4)}`;
}
