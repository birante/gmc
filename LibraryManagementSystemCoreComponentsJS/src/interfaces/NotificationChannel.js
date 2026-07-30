// Strategy: how to deliver a notification (console, in-memory, email…).

export class NotificationChannel {
  send(recipient, message) {
    throw new Error("NotificationChannel.send(recipient, message) not implemented");
  }
}
