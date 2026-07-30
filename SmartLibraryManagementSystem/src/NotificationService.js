export class NotificationService {
  #subscribers;

  constructor() {
    this.#subscribers = new Set();
  }

  subscribe(user) {
    this.#subscribers.add(user);
  }

  unsubscribe(user) {
    this.#subscribers.delete(user);
  }

  isSubscribed(user) {
    return this.#subscribers.has(user);
  }

  notify(user, message) {
    if (!this.#subscribers.has(user)) return false;
    user.notify(message);
    return true;
  }

  broadcast(message) {
    for (const user of this.#subscribers) {
      user.notify(message);
    }
  }
}
