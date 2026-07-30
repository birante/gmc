// Orchestrates a checkout: sum → shipping → tax → deliver → clear.
// Every collaborator (notifier) is injected so the service can be
// exercised without touching stdout.

import { PRICING } from "../utils/constants.js";

export class CheckoutService {
  #notifier;

  constructor({ notifier } = {}) {
    // notifier(user, message) — defaults to console; pass a fake in tests
    this.#notifier = notifier ?? ((user, msg) => console.log(`[receipt -> ${user.email}] ${msg}`));
  }

  quote(cart) {
    const subtotal = cart.total;
    const shipping = subtotal >= PRICING.FREE_SHIPPING_MIN ? 0 : PRICING.FLAT_SHIPPING_FEE;
    const tax      = (subtotal + shipping) * PRICING.TAX_RATE;
    const total    = subtotal + shipping + tax;
    return { subtotal, shipping, tax, total };
  }

  checkout(cart, user) {
    if (cart.isEmpty) throw new Error("Cannot checkout an empty cart.");
    if (!user?.email) throw new Error("Cannot checkout without a user email.");
    const quote = this.quote(cart);
    this.#notifier(user, `Order total: $${quote.total.toFixed(2)} (subtotal $${quote.subtotal.toFixed(2)}, shipping $${quote.shipping.toFixed(2)}, tax $${quote.tax.toFixed(2)})`);
    cart.clear();
    return quote;
  }
}
