'use strict';

/** Minimal async mock function that records its calls. */
function mockFn(impl = async () => {}) {
  const fn = async (...args) => {
    fn.calls.push(args);
    return impl(...args);
  };
  fn.calls = [];
  return fn;
}

const silentLogger = { log() {}, warn() {}, error() {}, info() {} };

module.exports = { mockFn, silentLogger };
