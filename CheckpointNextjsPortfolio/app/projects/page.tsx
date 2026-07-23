import type { Metadata } from "next";
import { getProjects } from "@/lib/projects";
import ProjectCard from "@/components/ProjectCard";
import styles from "./projects.module.css";

export const metadata: Metadata = {
  title: "Projects — Birante Sy",
  description: "A selection of projects I've built.",
};

// This is an async Server Component: `getProjects()` is awaited on the
// server before the HTML is sent to the browser. That is Server-Side
// Rendering (SSR) as required by the checkpoint.
export default async function ProjectsPage() {
  const projects = await getProjects();

  return (
    <section className={styles.container}>
      <h1>Projects</h1>
      <p className={styles.lead}>
        A few things I&apos;ve built recently.
      </p>

      <div className={styles.grid}>
        {projects.map((project) => (
          <ProjectCard key={project.id} project={project} />
        ))}
      </div>
    </section>
  );
}
