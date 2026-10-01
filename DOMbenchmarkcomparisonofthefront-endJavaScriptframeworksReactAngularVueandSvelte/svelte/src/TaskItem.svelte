<script>
  import { PRIORITIES } from './tasks.js';

  let { task, editing, onedit, onsave, oncancel, onremove } = $props();

  let draftName = $state('');
  let draftPriority = $state('medium');

  function startEdit() {
    draftName = task.name;
    draftPriority = task.priority;
    onedit(task.id);
  }
</script>

{#if editing}
  <li class="task editing" data-testid="task" data-id={task.id}>
    <input class="edit-name" data-testid="edit-name" bind:value={draftName} />
    <select class="edit-priority" data-testid="edit-priority" bind:value={draftPriority}>
      {#each PRIORITIES as p (p)}
        <option value={p}>{p}</option>
      {/each}
    </select>
    <button type="button" class="save" data-testid="save" onclick={() => onsave(task.id, draftName, draftPriority)}>Save</button>
    <button type="button" class="cancel" data-testid="cancel" onclick={oncancel}>Cancel</button>
  </li>
{:else}
  <!-- Tags are written without whitespace between them on purpose: Svelte keeps
       inter-element whitespace as text nodes, React/Vue/Angular strip it. This keeps
       the DOM node count comparable with the other three apps. -->
  <li class="task" data-testid="task" data-id={task.id}><span class="task-name">{task.name}</span><span
      class="badge priority-{task.priority}" data-testid="priority">{task.priority}</span><button
      type="button" class="edit" data-testid="edit" onclick={startEdit}>Edit</button><button
      type="button" class="remove" data-testid="remove" onclick={() => onremove(task.id)}>Remove</button></li>
{/if}
