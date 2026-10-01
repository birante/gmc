<script setup>
import { ref } from 'vue';
import { PRIORITIES } from './tasks.js';

const props = defineProps({ task: Object, editing: Boolean });
const emit = defineEmits(['edit', 'save', 'cancel', 'remove']);

const draftName = ref('');
const draftPriority = ref('medium');

function startEdit() {
  draftName.value = props.task.name;
  draftPriority.value = props.task.priority;
  emit('edit', props.task.id);
}
</script>

<template>
  <li v-if="editing" class="task editing" data-testid="task" :data-id="task.id">
    <input class="edit-name" data-testid="edit-name" v-model="draftName" />
    <select class="edit-priority" data-testid="edit-priority" v-model="draftPriority">
      <option v-for="p in PRIORITIES" :key="p" :value="p">{{ p }}</option>
    </select>
    <button type="button" class="save" data-testid="save" @click="emit('save', task.id, draftName, draftPriority)">Save</button>
    <button type="button" class="cancel" data-testid="cancel" @click="emit('cancel')">Cancel</button>
  </li>
  <li v-else class="task" data-testid="task" :data-id="task.id">
    <span class="task-name">{{ task.name }}</span>
    <span :class="['badge', 'priority-' + task.priority]" data-testid="priority">{{ task.priority }}</span>
    <button type="button" class="edit" data-testid="edit" @click="startEdit">Edit</button>
    <button type="button" class="remove" data-testid="remove" @click="emit('remove', task.id)">Remove</button>
  </li>
</template>
