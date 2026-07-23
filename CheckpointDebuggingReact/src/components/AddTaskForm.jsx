import { useState } from "react";

// FIX #6 (uncontrolled → controlled input):
//   Buggy version initialized `useState()` with no argument, making
//   the value `undefined`. React warned:
//     "A component is changing an uncontrolled input to be controlled."
//   In DevTools → Components, the hook value showed as `undefined`
//   the first render and then a string on the next — exactly the
//   uncontrolled-to-controlled transition.
//   Fix: initialize state with an empty string.

export default function AddTaskForm({ onAdd }) {
  const [description, setDescription] = useState("");

  const handleSubmit = (event) => {
    event.preventDefault();
    const trimmed = description.trim();
    if (!trimmed) return;
    onAdd(trimmed);
    setDescription("");
  };

  return (
    <form className="add-task" onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="What needs to be done?"
        value={description}
        onChange={(event) => setDescription(event.target.value)}
      />
      <button type="submit">Add</button>
    </form>
  );
}
