<script>
  import TaskItem from './TaskItem.svelte';
  import { PRIORITIES, buildTasks, makeTask, nextPriority } from './tasks.js';

  // Svelte 5 runes: $state makes the array and its objects deeply reactive.
  // The compiler turns the markup into direct DOM operations, so a change to
  // task.name only updates that one text node - there is no virtual DOM diff.
  let tasks = $state([]);
  let editingId = $state(null);
  let name = $state('');
  let priority = $state('medium');

  function addTask(event) {
    event.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) return;
    tasks.push(makeTask(trimmed, priority));
    name = '';
  }

  function onSave(id, newName, newPriority) {
    const task = tasks.find((t) => t.id === id);
    if (task) {
      task.name = newName.trim() || task.name;
      task.priority = newPriority;
    }
    editingId = null;
  }

  function onRemove(id) {
    const index = tasks.findIndex((t) => t.id === id);
    if (index !== -1) tasks.splice(index, 1);
  }

  // Benchmark operations
  function run(n) {
    editingId = null;
    tasks = buildTasks(n);
  }
  function update50() {
    for (let i = 0; i < 50 && i < tasks.length; i++) {
      tasks[i].name += ' !!!';
      tasks[i].priority = nextPriority(tasks[i].priority);
    }
  }
  function delete50() {
    tasks.splice(0, 50);
  }
  function clear() {
    editingId = null;
    tasks = [];
  }
</script>

<main id="app" class="container" data-framework="svelte">
  <h1>To-Do List <small>(Svelte)</small></h1>

  <form id="add-form" data-testid="add-form" onsubmit={addTask}>
    <input id="task-name" data-testid="task-name" placeholder="Task name" bind:value={name} />
    <select id="task-priority" data-testid="task-priority" bind:value={priority}>
      {#each PRIORITIES as p (p)}
        <option value={p}>{p}</option>
      {/each}
    </select>
    <button id="add-task" data-testid="add-task" type="submit">Add</button>
  </form>

  <div id="bench" class="bench" data-testid="bench">
    <button id="run-100" data-testid="run-100" type="button" onclick={() => run(100)}>Render 100</button>
    <button id="run-500" data-testid="run-500" type="button" onclick={() => run(500)}>Render 500</button>
    <button id="run-1000" data-testid="run-1000" type="button" onclick={() => run(1000)}>Render 1000</button>
    <button id="update-50" data-testid="update-50" type="button" onclick={update50}>Update 50</button>
    <button id="delete-50" data-testid="delete-50" type="button" onclick={delete50}>Delete 50</button>
    <button id="clear" data-testid="clear" type="button" onclick={clear}>Clear</button>
  </div>

  <p id="task-count" data-testid="task-count">{tasks.length} tasks</p>

  <ul id="task-list" data-testid="task-list">
    {#each tasks as task (task.id)}
      <TaskItem
        {task}
        editing={task.id === editingId}
        onedit={(id) => (editingId = id)}
        onsave={onSave}
        oncancel={() => (editingId = null)}
        onremove={onRemove}
      />
    {/each}
  </ul>
  {#if tasks.length === 0}
    <p class="empty" data-testid="empty">No tasks yet.</p>
  {/if}
</main>
