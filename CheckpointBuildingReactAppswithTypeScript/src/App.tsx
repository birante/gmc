import Greeting from "./components/Greeting";
import Counter from "./components/Counter";
import "./App.css";

function App() {
  return (
    <div className="app">
      <h1>React + TypeScript Checkpoint</h1>

      <section>
        <h2>Code 01 — Functional Component</h2>
        <Greeting name="Birante" />
      </section>

      <section>
        <h2>Code 02 — Class Component</h2>
        <Counter />
      </section>
    </div>
  );
}

export default App;
