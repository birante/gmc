// Concrete NotificationChannel implementations. Each fulfils the same
// send(recipient, message) contract but delivers through a different
// medium. Consumers depend on the abstraction, not on any concrete one.

import { NotificationChannel } from "../interfaces/NotificationChannel.js";

export class ConsoleChannel extends NotificationChannel {
  send(recipient, message) {
    console.log(`[console -> ${recipient.name} <${recipient.email}>] ${message}`);
  }
}

// Records every delivery in memory — useful for tests to assert what was
// sent without touching stdout.
export class InMemoryChannel extends NotificationChannel {
  constructor() { super(); this.sent = []; }
  send(recipient, message) {
    this.sent.push({ recipientId: recipient.id, message, at: new Date() });
  }
}

// Stub of an email/SMS gateway — kept as a no-op so the demo does not
// send anything real, but shows how a new channel plugs in.
export class EmailChannel extends NotificationChannel {
  #gateway;
  constructor(gateway) { super(); this.#gateway = gateway; }
  send(recipient, message) {
    this.#gateway.enqueue({ to: recipient.email, body: message });
  }
}
