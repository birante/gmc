import type { Metadata } from "next";
import ContactForm from "./ContactForm";
import styles from "./contact.module.css";

export const metadata: Metadata = {
  title: "Contact — Birante Sy",
  description: "Get in touch — email, socials, and a message form.",
};

export default function ContactPage() {
  return (
    <section className={styles.container}>
      <h1>Contact</h1>
      <p className={styles.lead}>
        Have a question, an idea, or just want to say hi? Drop a message
        below or reach me directly.
      </p>

      <div className={styles.grid}>
        <div className={styles.info}>
          <h2 className={styles.infoTitle}>Direct</h2>
          <ul className={styles.list}>
            <li>
              <span className={styles.label}>Email</span>
              <a href="mailto:birante.sy@pasteur.sn">birante.sy@pasteur.sn</a>
            </li>
            <li>
              <span className={styles.label}>GitHub</span>
              <a
                href="https://github.com/"
                target="_blank"
                rel="noreferrer"
              >
                @birantesy
              </a>
            </li>
            <li>
              <span className={styles.label}>Location</span>
              <span>Dakar, Senegal</span>
            </li>
          </ul>
        </div>

        <ContactForm />
      </div>
    </section>
  );
}
