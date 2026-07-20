import { createSlice, nanoid } from '@reduxjs/toolkit'

const initialState = {
  tasks: [
    { id: nanoid(), description: 'Learn Redux Toolkit', isDone: true },
    { id: nanoid(), description: 'Build the ToDo checkpoint', isDone: false },
  ],
  filter: 'all',
}

const tasksSlice = createSlice({
  name: 'tasks',
  initialState,
  reducers: {
    addTask: {
      reducer(state, action) {
        state.tasks.push(action.payload)
      },
      prepare(description) {
        return { payload: { id: nanoid(), description, isDone: false } }
      },
    },
    toggleTask(state, action) {
      const task = state.tasks.find((t) => t.id === action.payload)
      if (task) task.isDone = !task.isDone
    },
    editTask(state, action) {
      const { id, description } = action.payload
      const task = state.tasks.find((t) => t.id === id)
      if (task) task.description = description
    },
    deleteTask(state, action) {
      state.tasks = state.tasks.filter((t) => t.id !== action.payload)
    },
    setFilter(state, action) {
      state.filter = action.payload
    },
  },
})

export const { addTask, toggleTask, editTask, deleteTask, setFilter } =
  tasksSlice.actions

export const selectFilteredTasks = (state) => {
  const { tasks, filter } = state.tasks
  if (filter === 'done') return tasks.filter((t) => t.isDone)
  if (filter === 'notDone') return tasks.filter((t) => !t.isDone)
  return tasks
}

export const selectFilter = (state) => state.tasks.filter

export default tasksSlice.reducer
