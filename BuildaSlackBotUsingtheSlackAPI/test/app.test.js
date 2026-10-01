'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { registerListeners } = require('../src/app');
const { handleMessage } = require('../src/handlers/messageHandler');
const { handleHelloCommand } = require('../src/handlers/helloCommand');

test('registerListeners wires message event, message replies and /hello', () => {
  const calls = [];
  const fakeApp = {
    event: (name, fn) => calls.push(['event', name, fn]),
    message: (fn) => calls.push(['message', fn]),
    command: (name, fn) => calls.push(['command', name, fn]),
    error: (fn) => calls.push(['error', fn]),
  };
  registerListeners(fakeApp, { logMessage: () => {} });

  assert.equal(calls.find((c) => c[0] === 'event')[1], 'message');
  assert.equal(calls.find((c) => c[0] === 'message')[1], handleMessage);
  const cmd = calls.find((c) => c[0] === 'command');
  assert.equal(cmd[1], '/hello');
  assert.equal(cmd[2], handleHelloCommand);
});
