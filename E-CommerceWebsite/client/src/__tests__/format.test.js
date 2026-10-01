import { formatPrice, STATUS_LABELS } from '../utils/format.js';

describe('formatPrice', () => {
  it('formate en FCFA avec séparateur de milliers', () => {
    expect(formatPrice(18500)).toBe('18 500 FCFA');
    expect(formatPrice(1500000)).toBe('1 500 000 FCFA');
    expect(formatPrice(0)).toBe('0 FCFA');
  });
  it('libellés de statut en français', () => {
    expect(STATUS_LABELS.pending).toBe('En attente');
    expect(STATUS_LABELS.delivered).toBe('Livrée');
  });
});
