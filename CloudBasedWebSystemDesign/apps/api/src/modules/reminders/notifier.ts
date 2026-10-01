import type { Logger } from 'pino';

/**
 * Port for outbound SMS. The default adapter only logs; a production adapter
 * (e.g. Orange SMS API, Twilio, Africa's Talking) implements the same interface
 * and is selected through the SMS_PROVIDER environment variable.
 */
export interface SmsNotifier {
  send(to: string, message: string): Promise<void>;
}

export class ConsoleSmsNotifier implements SmsNotifier {
  constructor(private readonly log: Logger) {}

  async send(to: string, message: string): Promise<void> {
    this.log.info({ to, message }, 'SMS reminder (console provider)');
  }
}

/** Test double that records messages in memory. */
export class InMemorySmsNotifier implements SmsNotifier {
  readonly sent: Array<{ to: string; message: string }> = [];

  async send(to: string, message: string): Promise<void> {
    this.sent.push({ to, message });
  }
}
