// ─────────────────────────────────────────────────────────────
// Code 01 — Converted from JavaScript to TypeScript
//
// Conversion notes:
//   1. The file extension is `.tsx` instead of `.jsx` because the
//      component returns JSX AND the file contains type annotations.
//   2. `GreetingProps` describes the shape of the props object.
//      `name` is declared as a required `string`, so consumers who
//      forget it (or pass a number) get a compile-time error.
//   3. The component is typed as `React.FC<GreetingProps>`
//      (Function Component of GreetingProps). This gives us prop
//      auto-completion and type safety at every call site.
//   4. The return type `JSX.Element` is inferred automatically from
//      the JSX body — no need to annotate it explicitly.
// ─────────────────────────────────────────────────────────────

import React from "react";

interface GreetingProps {
  name: string;
}

const Greeting: React.FC<GreetingProps> = ({ name }) => {
  return <div>Hello, {name}!</div>;
};

export default Greeting;
