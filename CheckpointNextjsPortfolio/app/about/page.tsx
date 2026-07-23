import type { Metadata } from "next";
import styles from "./about.module.css";

export const metadata: Metadata = {
  title: "About — Birante Sy",
  description: "About me, my background, and how I work.",
};

const timeline = [
  {
    year: "2024 — Present",
    title: "Full-stack developer",
    text: "Building React / Next.js apps and Node.js services at GoMyCode.",
  },
  {
    year: "2023",
    title: "Started the GoMyCode bootcamp",
    text: "Front-end, algorithms, data structures, TypeScript, Redux, Next.js.",
  },
  {
    year: "Before that",
    title: "Self-taught fundamentals",
    text: "HTML, CSS, JavaScript, Git — the classic path.",
  },
];

export default function AboutPage() {
  return (
    <section className={styles.container}>
      <h1>About me</h1>
      <p className={styles.lead}>
        I&apos;m a developer who enjoys turning ideas into working products.
        I care about clean code, thoughtful UI, and shipping fast without
        breaking things.
      </p>

      <h2 className={styles.subheading}>Journey</h2>
      <ol className={styles.timeline}>
        {timeline.map((item) => (
          <li key={item.year} className={styles.item}>
            <div className={styles.year}>{item.year}</div>
            <div>
              <h3 className={styles.title}>{item.title}</h3>
              <p className={styles.text}>{item.text}</p>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}
