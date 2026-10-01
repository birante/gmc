// Shared task data helpers - the same logic exists in every app (react, vue, svelte, angular)
// so that each framework renders exactly the same data.
export type Priority = "low" | "medium" | "high";
export interface Task { id: number; name: string; priority: Priority; }
export const PRIORITIES: Priority[] = ["low", "medium", "high"];

const ADJECTIVES = ['quick', 'urgent', 'small', 'large', 'weekly', 'daily', 'pending', 'shared', 'final', 'simple'];
const VERBS = ['write', 'review', 'fix', 'plan', 'call', 'test', 'deploy', 'clean', 'read', 'design'];
const NOUNS = ['report', 'email', 'bug', 'meeting', 'invoice', 'docs', 'release', 'backlog', 'slides', 'budget'];

let nextId = 1;

export function makeTask(name: string, priority: Priority): Task {
  return { id: nextId++, name, priority };
}

/** Build `count` deterministic tasks (names + cycling priorities). */
export function buildTasks(count: number): Task[] {
  const tasks = new Array<Task>(count);
  for (let i = 0; i < count; i++) {
    const id = nextId++;
    tasks[i] = {
      id,
      name: `${VERBS[id % 10]} ${ADJECTIVES[(id * 7) % 10]} ${NOUNS[(id * 3) % 10]} #${id}`,
      priority: PRIORITIES[id % 3],
    };
  }
  return tasks;
}

export function nextPriority(p: Priority): Priority {
  return PRIORITIES[(PRIORITIES.indexOf(p) + 1) % PRIORITIES.length];
}
