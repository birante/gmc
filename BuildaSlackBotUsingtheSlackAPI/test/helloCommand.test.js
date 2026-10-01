'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { handleHelloCommand } = require('../src/handlers/helloCommand');
const { mockFn, silentLogger } = require('./helpers');

const baseCommand = { command: '/hello', text: '', user_id: 'U42', channel_id: 'C99' };

test('/hello acks first, then greets the caller in the channel', async () => {
  const order = [];
  const ack = mockFn(async () => order.push('ack'));
  const say = mockFn(async () => order.push('say'));
  const respond = mockFn();

  await handleHelloCommand({ command: baseCommand, ack, say, respond });

  assert.deepEqual(order, ['ack', 'say']);
  assert.equal(ack.calls.length, 1);
  assert.match(say.calls[0][0], /^Hello <@U42>!/);
  assert.match(say.calls[0][0], /<#C99>/);
  assert.equal(respond.calls.length, 0);
});

test('/hello <name> greets the given name', async () => {
  const say = mockFn();
  await handleHelloCommand({ command: { ...baseCommand, text: '  Alice ' }, ack: mockFn(), say, respond: mockFn() });
  assert.match(say.calls[0][0], /^Hello Alice!/);
});

test('/hello falls back to an ephemeral respond() when say() fails', async () => {
  const say = mockFn(async () => { throw new Error('not_in_channel'); });
  const respond = mockFn();
  await handleHelloCommand({ command: baseCommand, ack: mockFn(), say, respond, logger: silentLogger });
  assert.equal(respond.calls.length, 1);
  assert.equal(respond.calls[0][0].response_type, 'ephemeral');
  assert.match(respond.calls[0][0].text, /Hello <@U42>/);
});
