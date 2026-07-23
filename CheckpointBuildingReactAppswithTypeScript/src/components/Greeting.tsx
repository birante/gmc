// ─────────────────────────────────────────────────────────────
// Code 01 — Converted from JavaScript to TypeScript
//
// Conversion notes:
//   1. The file extension is `.tsx` instead of `.jsx` because
//      the component returns JSX and the file contains type
//      annotations.
//   2. We define an interface `GreetingProps` that describes the
//      shape of the props object. `name` is a required `string`.
//   3. The functional component is typed as
//      `React.FC<GreetingProps>` (Function Component of
//      GreetingProps). This gives us prop-checking and IntelliSense
//      on `{ name }` at the call site.
// ─────────────────────────────────────────────────────────────

import React from "react";

interface GreetingProps {
  name: string;
}

const Greeting: React.FC<GreetingProps> = ({ name }) => {
  return <div>Hello, {name}!</div>;
};

export default Greeting;
