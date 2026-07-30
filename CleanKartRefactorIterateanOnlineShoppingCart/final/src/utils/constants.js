// Central place for the numeric policy the shop uses.
// Every "magic number" that lived inside checkout() in v0 lives here now.

export const PRICING = Object.freeze({
  TAX_RATE:              0.08,
  FLAT_SHIPPING_FEE:     10,
  FREE_SHIPPING_MIN:     50,
});
