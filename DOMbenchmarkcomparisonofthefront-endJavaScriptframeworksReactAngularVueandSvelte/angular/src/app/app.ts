import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TaskItem } from './task-item';
import { PRIORITIES, Priority, Task, buildTasks, makeTask, nextPriority } from './tasks';

@Component({
  // Attribute selector: <div id="root" app-root> keeps the same wrapper as the other apps.
  selector: '[app-root]',
  imports: [FormsModule, TaskItem],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './app.html',
})
export class App {
  protected readonly priorities = PRIORITIES;
  protected readonly tasks = signal<Task[]>([]);
  protected readonly editingId = signal<number | null>(null);

  // Two-way bound with [(ngModel)] in the "add task" form.
  protected name = '';
  protected priority: Priority = 'medium';

  protected addTask(): void {
    const trimmed = this.name.trim();
    if (!trimmed) return;
    this.tasks.update((ts) => [...ts, makeTask(trimmed, this.priority)]);
    this.name = '';
  }

  protected onSave(e: { id: number; name: string; priority: Priority }): void {
    const trimmed = e.name.trim();
    this.tasks.update((ts) => ts.map((t) => (t.id === e.id ? { ...t, name: trimmed || t.name, priority: e.priority } : t)));
    this.editingId.set(null);
  }

  protected onRemove(id: number): void {
    this.tasks.update((ts) => ts.filter((t) => t.id !== id));
  }

  // Benchmark operations
  protected run(n: number): void {
    this.editingId.set(null);
    this.tasks.set(buildTasks(n));
  }
  protected update50(): void {
    // Immutable update: only 50 rows get a new object -> only those OnPush rows re-render.
    this.tasks.update((ts) =>
      ts.map((t, i) => (i < 50 ? { ...t, name: t.name + ' !!!', priority: nextPriority(t.priority) } : t)),
    );
  }
  protected delete50(): void {
    this.tasks.update((ts) => ts.slice(50));
  }
  protected clear(): void {
    this.editingId.set(null);
    this.tasks.set([]);
  }
}
