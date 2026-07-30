// Observer Pattern — a topic-per-event hub. Recipients subscribe with a
// NotificationChannel; when a service publishes, the hub fans out through
// every channel registered for that recipient on that topic.
//
// Decouples "something happened" (services) from "who cares and how they
// want to hear about it" (channels).

export class NotificationHub {
  #subscriptions;

  constructor() {
    // topic -> Map<recipient, NotificationChannel[]>
    this.#subscriptions = new Map();
  }

  subscribe(topic, recipient, channel) {
    if (!this.#subscriptions.has(topic)) {
      this.#subscriptions.set(topic, new Map());
    }
    const byRecipient = this.#subscriptions.get(topic);
    if (!byRecipient.has(recipient)) byRecipient.set(recipient, []);
    byRecipient.get(recipient).push(channel);
  }

  unsubscribeAll(recipient) {
    for (const byRecipient of this.#subscriptions.values()) {
      byRecipient.delete(recipient);
    }
  }

  publish(topic, recipient, message) {
    const byRecipient = this.#subscriptions.get(topic);
    if (!byRecipient) return 0;
    const channels = byRecipient.get(recipient);
    if (!channels?.length) return 0;
    let delivered = 0;
    for (const ch of channels) {
      try {
        ch.send(recipient, message);
        delivered += 1;
      } catch (err) {
        // one bad channel must not break the fan-out
        console.error(`[NotificationHub] channel failed: ${err.message}`);
      }
    }
    return delivered;
  }
}

export const Topics = Object.freeze({
  LOAN_CREATED:  "loan.created",
  LOAN_RETURNED: "loan.returned",
  LOAN_OVERDUE:  "loan.overdue",
  FINE_ISSUED:   "fine.issued",
});
