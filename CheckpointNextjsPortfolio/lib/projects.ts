import type { Project } from "@/components/ProjectCard";

// A pretend "fetch" — in a real portfolio this could hit a CMS or GitHub API.
// The `await` makes it obvious that the page rendering it will be an
// async server component (Server-Side Rendering).
export async function getProjects(): Promise<Project[]> {
  return [
    {
      id: "redux-todo",
      title: "Redux To-Do App",
      description:
        "A React To-Do list wired to a Redux Toolkit store. Add, edit, filter and toggle tasks — global state managed with slices and selectors.",
      image: "/images/project-redux.svg",
      tags: ["React", "Redux Toolkit", "Vite"],
    },
    {
      id: "slack-bot",
      title: "Slack Bot with Bolt.js",
      description:
        "A Node.js Slack bot using @slack/bolt in Socket Mode. Responds to /hello, listens to channel messages, and greets on mentions.",
      image: "/images/project-slack.svg",
      tags: ["Node.js", "Slack API", "Bolt"],
    },
    {
      id: "ts-conversion",
      title: "React → TypeScript Conversion",
      description:
        "Migrated a functional and a class-based React component to TypeScript with strongly-typed props, state and event handlers.",
      image: "/images/project-typescript.svg",
      tags: ["React", "TypeScript", "Vite"],
    },
  ];
}
