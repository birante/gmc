<script setup>
import { ref } from 'vue';
import TaskItem from './TaskItem.vue';
import { PRIORITIES, buildTasks, makeTask, nextPriority } from './tasks.js';

// Vue's reactivity system tracks the array and every task object (deep proxy),
// so in-place mutations only re-render the components that read the changed fields.
const tasks = ref([]);
const editingId = ref(null);
const name = ref('');
const priority = ref('medium');

function addTask() {
  const trimmed = name.value.trim();
  if (!trimmed) return;
  tasks.value.push(makeTask(trimmed, priority.value));
  name.value = '';
}

function onSave(id, newName, newPriority) {
  const task = tasks.value.find((t) => t.id === id);
  if (task) {
    task.name = newName.trim() || task.name;
    task.priority = newPriority;
  }
  editingId.value = null;
}

function onRemove(id) {
  const index = tasks.value.findIndex((t) => t.id === id);
  if (index !== -1) tasks.value.splice(index, 1);
}

// Benchmark operations
function run(n) {
  editingId.value = null;
  tasks.value = buildTasks(n);
}
function update50() {
  const list = tasks.value;
  for (let i = 0; i < 50 && i < list.length; i++) {
    list[i].name += ' !!!';
    list[i].priority = nextPriority(list[i].priority);
  }
}
function delete50() {
  tasks.value.splice(0, 50);
}
function clear() {
  editingId.value = null;
  tasks.value = [];
}
</script>

<template>
  <main id="app" class="container" data-framework="vue">
    <h1>To-Do List <small>(Vue)</small></h1>

    <form id="add-form" data-testid="add-form" @submit.prevent="addTask">
      <input id="task-name" data-testid="task-name" placeholder="Task name" v-model="name" />
      <select id="task-priority" data-testid="task-priority" v-model="priority">
        <option v-for="p in PRIORITIES" :key="p" :value="p">{{ p }}</option>
      </select>
      <button id="add-task" data-testid="add-task" type="submit">Add</button>
    </form>

    <div id="bench" class="bench" data-testid="bench">
      <button id="run-100" data-testid="run-100" type="button" @click="run(100)">Render 100</button>
      <button id="run-500" data-testid="run-500" type="button" @click="run(500)">Render 500</button>
      <button id="run-1000" data-testid="run-1000" type="button" @click="run(1000)">Render 1000</button>
      <button id="update-50" data-testid="update-50" type="button" @click="update50">Update 50</button>
      <button id="delete-50" data-testid="delete-50" type="button" @click="delete50">Delete 50</button>
      <button id="clear" data-testid="clear" type="button" @click="clear">Clear</button>
    </div>

    <p id="task-count" data-testid="task-count">{{ tasks.length }} tasks</p>

    <ul id="task-list" data-testid="task-list">
      <TaskItem
        v-for="task in tasks"
        :key="task.id"
        :task="task"
        :editing="task.id === editingId"
        @edit="editingId = $event"
        @save="onSave"
        @cancel="editingId = null"
        @remove="onRemove"
      />
    </ul>
    <p v-if="tasks.length === 0" class="empty" data-testid="empty">No tasks yet.</p>
  </main>
</template>
