import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PRIORITIES, Priority, Task } from './tasks';

/**
 * One row of the list. OnPush: Angular only re-checks this component when its
 * `task` input receives a new object reference (immutable updates in App) or
 * when one of its own events fires.
 * The host element is the <li> itself (attribute selector) so the DOM is identical
 * to the React / Vue / Svelte versions: ul#task-list > li.task.
 */
@Component({
  selector: 'li[app-task-item]',
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'task',
    '[class.editing]': 'editing()',
    'data-testid': 'task',
    '[attr.data-id]': 'task().id',
  },
  template: `
    @if (editing()) {
      <input class="edit-name" data-testid="edit-name" [(ngModel)]="draftName" />
      <select class="edit-priority" data-testid="edit-priority" [(ngModel)]="draftPriority">
        @for (p of priorities; track p) {
          <option [value]="p">{{ p }}</option>
        }
      </select>
      <button type="button" class="save" data-testid="save" (click)="save.emit({ id: task().id, name: draftName, priority: draftPriority })">Save</button>
      <button type="button" class="cancel" data-testid="cancel" (click)="cancel.emit()">Cancel</button>
    } @else {
      <span class="task-name">{{ task().name }}</span>
      <span class="badge priority-{{ task().priority }}" data-testid="priority">{{ task().priority }}</span>
      <button type="button" class="edit" data-testid="edit" (click)="startEdit()">Edit</button>
      <button type="button" class="remove" data-testid="remove" (click)="remove.emit(task().id)">Remove</button>
    }
  `,
})
export class TaskItem {
  readonly task = input.required<Task>();
  readonly editing = input(false);
  readonly edit = output<number>();
  readonly save = output<{ id: number; name: string; priority: Priority }>();
  readonly cancel = output<void>();
  readonly remove = output<number>();

  protected readonly priorities = PRIORITIES;
  // Two-way bound with [(ngModel)] while the row is in edit mode.
  protected draftName = '';
  protected draftPriority: Priority = 'medium';

  protected startEdit(): void {
    this.draftName = this.task().name;
    this.draftPriority = this.task().priority;
    this.edit.emit(this.task().id);
  }
}
