import Image from "next/image";
import Link from "next/link";
import styles from "./page.module.css";

const skills = [
  "React",
  "Next.js",
  "TypeScript",
  "Redux Toolkit",
  "Node.js",
  "CSS",
];

export default function HomePage() {
  return (
    <section className={styles.hero}>
      <div className={styles.avatarWrapper}>
        <Image
          src="/images/avatar.svg"
          alt="Profile picture"
          width={160}
          height={160}
          priority
          className={styles.avatar}
        />
      </div>

      <h1 className={styles.title}>
        Hi, I&apos;m <span className={styles.accent}>Birante</span> 👋
      </h1>
      <p className={styles.subtitle}>
        Full-stack developer building modern web apps with React, Next.js,
        and TypeScript.
      </p>

      <div className={styles.skills}>
        {skills.map((skill) => (
          <span key={skill} className={styles.skill}>
            {skill}
          </span>
        ))}
      </div>

      <div className={styles.actions}>
        <Link href="/projects" className={styles.primaryBtn}>
          See my projects
        </Link>
        <Link href="/contact" className={styles.secondaryBtn}>
          Get in touch
        </Link>
      </div>
    </section>
  );
}
