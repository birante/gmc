import { useEffect, useState } from "react";

// FIX #3 (stale state in interval) + FIX #4 (missing cleanup):
//
//   Buggy version #3:
//     setInterval(() => setSeconds(seconds + 1), 1000);
//   `seconds` in the callback was captured in a closure the first
//   time the effect ran → it stayed 0 forever, so the counter jumped
//   from 0 to 1 and got stuck.
//   Fix: use the updater form `setSeconds((prev) => prev + 1)`.
//
//   Buggy version #4: the useEffect never returned a cleanup, so
//   every re-render stacked another setInterval on top. In React
//   DevTools → Profiler, you could see LiveCounter re-rendering
//   more and more times per second — a classic memory leak.
//   Fix: return `() => clearInterval(id)` from the effect.

export default function LiveCounter() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setSeconds((prev) => prev + 1);
    }, 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <span className="live-counter" aria-label="Seconds since page load">
      ⏱ {seconds}s since page load
    </span>
  );
}
