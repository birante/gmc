# Building React Apps with TypeScript — Checkpoint

Convert two React components from **JavaScript to TypeScript**:

- **Code 01** — a functional `Greeting` component that takes a `name` prop
- **Code 02** — a class-based `Counter` component with local state

## Project structure

```text
src/
├── App.tsx                     # renders both converted components
├── main.tsx
└── components/
    ├── Greeting.tsx            # Code 01 — functional component in TS
    └── Counter.tsx             # Code 02 — class component in TS
```

## Steps I followed to convert the code

### 1. Set up a TypeScript-ready project

Scaffolded a Vite React + TypeScript project so `.tsx` files are compiled
out of the box:

```bash
npm create vite@latest . -- --template react-ts
npm install
```

Vite ships with a `tsconfig.json` already configured for React + strict
type-checking, so no extra config was needed.

### 2. Rename files from `.jsx` → `.tsx`

Any file that contains JSX **and** TypeScript type annotations must use
the `.tsx` extension. Files with only TypeScript (no JSX) can stay `.ts`.

### 3. Convert Code 01 — functional component

**Before (JavaScript):**

```jsx
const Greeting = ({ name }) => {
  return <div>Hello, {name}!</div>;
};
```

**After (TypeScript):**

```tsx
interface GreetingProps {
  name: string;
}

const Greeting: React.FC<GreetingProps> = ({ name }) => {
  return <div>Hello, {name}!</div>;
};
```

**What changed:**

- Added a `GreetingProps` interface describing the props object.
- Typed the component as `React.FC<GreetingProps>` so consumers get
  compile-time errors if they pass a wrong prop (or forget `name`).

### 4. Convert Code 02 — class component

**Before (JavaScript):**

```jsx
class Counter extends Component {
  state = { count: 0 };
  increment = () => {
    this.setState({ count: this.state.count + 1 });
  };
  render() { /* ... */ }
}
```

**After (TypeScript):**

```tsx
import { Component, type MouseEvent } from "react";

type CounterProps = Record<string, never>;
interface CounterState {
  count: number;
}

class Counter extends Component<CounterProps, CounterState> {
  state: CounterState = { count: 0 };

  handleIncrement = (_event: MouseEvent<HTMLButtonElement>): void => {
    this.setState((prev) => ({ count: prev.count + 1 }));
  };

  render() { /* ... */ }
}
```

**What changed:**

- `Component` takes two generic type parameters:
  `Component<Props, State>`. Passing `CounterProps` and `CounterState`
  tells TypeScript what `this.props` and `this.state` look like.
- `CounterProps` is typed as `Record<string, never>` rather than an
  empty interface `{}`. An empty interface matches *any* object and
  effectively disables prop-checking — `Record<string, never>` says
  "no props allowed" and catches accidental prop passes.
- Declared `CounterState` so `this.state.count` is a known `number`.
- Kept `handleIncrement` as an arrow class field so `this` is
  auto-bound — no `.bind(this)` needed in a constructor.
- The click handler is typed as
  `MouseEvent<HTMLButtonElement>` — TypeScript now knows the shape
  of the event object at that call site.
- Switched to the callback form of `setState((prev) => …)` — safer
  when React batches updates.

### 5. Wire everything into `App.tsx`

`App.tsx` imports both components and renders them so you can see the
converted code working in the browser.

## Getting started

```bash
npm install
npm run dev
```

Runs at [http://localhost:5173](http://localhost:5173).

## Building & type-checking

```bash
npm run build     # tsc + vite build (fails if there are type errors)
```

If `npm run build` succeeds, the TypeScript conversion is valid.
