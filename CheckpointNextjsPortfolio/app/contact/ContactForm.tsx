"use client";

import { useState, type FormEvent } from "react";
import styles from "./contact.module.css";

type Status = "idle" | "sent";

export default function ContactForm() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [status, setStatus] = useState<Status>("idle");

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    console.log("Contact form submitted:", { name, email, message });
    setStatus("sent");
    setName("");
    setEmail("");
    setMessage("");
  };

  return (
    <form className={styles.form} onSubmit={handleSubmit}>
      <h2 className={styles.infoTitle}>Send a message</h2>

      <label className={styles.field}>
        <span>Name</span>
        <input
          type="text"
          required
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
      </label>

      <label className={styles.field}>
        <span>Email</span>
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </label>

      <label className={styles.field}>
        <span>Message</span>
        <textarea
          rows={4}
          required
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
      </label>

      <button type="submit" className={styles.submit}>
        Send
      </button>

      {status === "sent" && (
        <p className={styles.success}>
          Thanks — I&apos;ll get back to you soon!
        </p>
      )}
    </form>
  );
}
