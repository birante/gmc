// ─────────────────────────────────────────────────────────────
// Code 02 — Converted from JavaScript to TypeScript
//
// Conversion notes:
//   1. Class components take TWO generic type parameters:
//        Component<Props, State>
//      Since this Counter takes no props, we declare `CounterProps`
//      as an empty object type. `CounterState` describes the local
//      state — here just `{ count: number }`.
//   2. State is declared with an explicit type annotation
//      (`state: CounterState = { count: 0 }`) so TypeScript knows
//      the shape even before it sees the initializer.
//   3. Class field methods (e.g. `increment = () => {}`) preserve
//      the `this` binding — no manual `.bind(this)` needed.
//   4. We use the callback form of `setState((prev) => ...)`.
//      This is a small improvement over the original: it avoids
//      relying on the possibly-stale `this.state.count` when
//      React batches state updates.
// ─────────────────────────────────────────────────────────────

import { Component } from "react";

interface CounterProps {}

interface CounterState {
  count: number;
}

class Counter extends Component<CounterProps, CounterState> {
  state: CounterState = {
    count: 0,
  };

  increment = (): void => {
    this.setState((prev) => ({ count: prev.count + 1 }));
  };

  render() {
    return (
      <div>
        <p>Count: {this.state.count}</p>
        <button onClick={this.increment}>Increment</button>
      </div>
    );
  }
}

export default Counter;
