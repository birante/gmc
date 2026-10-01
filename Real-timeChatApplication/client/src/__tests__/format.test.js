import { describe, expect, it } from 'vitest';
import { formatDay, initials, typingText } from '../utils/format.js';

describe('utilitaires de formatage', () => {
  it('calcule les initiales', () => {
    expect(initials('awa')).toBe('AW');
    expect(initials('Awa Diop')).toBe('AD');
    expect(initials('moussa.sow')).toBe('MS');
    expect(initials('')).toBe('?');
  });

  it("formate l'indicateur de saisie", () => {
    expect(typingText([])).toBe('');
    expect(typingText(['Awa'])).toBe("Awa est en train d'écrire…");
    expect(typingText(['Awa', 'Moussa'])).toBe("Awa et Moussa sont en train d'écrire…");
    expect(typingText(['A', 'B', 'C'])).toBe("3 personnes sont en train d'écrire…");
  });

  it('formate les séparateurs de jour', () => {
    const now = new Date(2026, 9, 1, 12);
    expect(formatDay(new Date(2026, 9, 1, 8), now)).toBe("Aujourd'hui");
    expect(formatDay(new Date(2026, 8, 30, 8), now)).toBe('Hier');
  });
});
