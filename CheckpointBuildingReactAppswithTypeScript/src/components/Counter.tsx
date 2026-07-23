// ─────────────────────────────────────────────────────────────
// Code 02 — Converted from JavaScript to TypeScript
//
// Conversion notes:
//   1. Class components take TWO generic type parameters:
//        Component<Props, State>
//      This Counter takes no props, so `CounterProps` is typed as
//      `Record<string, never>` (an object with no allowed keys).
//      This is preferred over `interface CounterProps {}` — an
//      empty interface is treated as `any` object and defeats
//      the purpose of TypeScript.
//   2. `CounterState` describes the local state (`{ count: number }`).
//      State is declared with an explicit annotation so TypeScript
//      knows the shape even before it sees the initializer.
//   3. Class field methods (e.g. `increment = () => {}`) preserve
//      the `this` binding — no manual `.bind(this)` needed in the
//      constructor.
//   4. The click handler uses the callback form of
//      `setState((prev) => ...)`. This is safer than
//      `setState({ count: this.state.count + 1 })` — React may
//      batch multiple updates, and the callback form guarantees we
//      read the freshest value.
//   5. The `onClick` handler is typed as
//      `React.MouseEvent<HTMLButtonElement>` — this lets TypeScript
//      catch mistakes like calling `.value` on the event target.
// ─────────────────────────────────────────────────────────────

import { Component, type MouseEvent } from "react";

type CounterProps = Record<string, never>;

interface CounterState {
  count: number;
}

class Counter extends Component<CounterProps, CounterState> {
  state: CounterState = {
    count: 0,
  };

  handleIncrement = (_event: MouseEvent<HTMLButtonElement>): void => {
    this.setState((prev) => ({ count: prev.count + 1 }));
  };

  render() {
    return (
      <div>
        <p>Count: {this.state.count}</p>
        <button onClick={this.handleIncrement}>Increment</button>
      </div>
    );
  }
}

export default Counter;
