import AddTask from './components/AddTask'
import ListTask from './components/ListTask'
import './App.css'

export default function App() {
  return (
    <div className="app">
      <h1>Redux ToDo</h1>
      <AddTask />
      <ListTask />
    </div>
  )
}
