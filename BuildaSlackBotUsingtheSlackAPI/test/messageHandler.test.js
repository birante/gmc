'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildReply, handleMessage, createMessageEventHandler } = require('../src/handlers/messageHandler');
const { mockFn, silentLogger } = require('./helpers');

test('buildReply greets on hello/hi/hey (case-insensitive)', () => {
  for (const text of ['hello', 'Hi there', 'HEY bot', 'bonjour']) {
    assert.equal(buildReply(text, 'U123'), 'Hey there <@U123>! :wave:');
  }
});

test('buildReply answers ping and help', () => {
  assert.match(buildReply('ping', 'U1'), /^pong/);
  assert.match(buildReply('help', 'U1'), /\/hello/);
});

test('buildReply returns null for unrelated or empty text', () => {
  assert.equal(buildReply('the weather is nice', 'U1'), null);
  assert.equal(buildReply('shell', 'U1'), null); // "hell" is not a greeting
  assert.equal(buildReply('', 'U1'), null);
  assert.equal(buildReply(undefined, 'U1'), null);
});

test('handleMessage replies with say() to a greeting', async () => {
  const say = mockFn();
  await handleMessage({ message: { text: 'hello', user: 'U42', channel: 'C1', ts: '1.1' }, say });
  assert.deepEqual(say.calls, [['Hey there <@U42>! :wave:']]);
});

test('handleMessage replies in thread when the message is in a thread', async () => {
  const say = mockFn();
  await handleMessage({ message: { text: 'ping', user: 'U1', thread_ts: '9.9', ts: '10.0' }, say });
  assert.equal(say.calls.length, 1);
  assert.equal(say.calls[0][0].thread_ts, '9.9');
  assert.match(say.calls[0][0].text, /pong/);
});

test('handleMessage ignores unrelated messages, bot messages and subtypes', async () => {
  const say = mockFn();
  await handleMessage({ message: { text: 'random chat', user: 'U1' }, say });
  await handleMessage({ message: { text: 'hello', bot_id: 'B1' }, say });
  await handleMessage({ message: { text: 'hello', user: 'U1', subtype: 'message_changed' }, say });
  await handleMessage({ message: undefined, say });
  assert.equal(say.calls.length, 0);
});

test('handleMessage does not throw when say() fails', async () => {
  const say = mockFn(async () => { throw new Error('not_in_channel'); });
  await assert.doesNotReject(handleMessage({ message: { text: 'hi', user: 'U1' }, say, logger: silentLogger }));
});

test('message event handler passes every event to the logger', async () => {
  const logged = [];
  const handler = createMessageEventHandler((e) => logged.push(e));
  const event = { type: 'message', text: 'anything', user: 'U1', channel: 'C1', ts: '1.0' };
  await handler({ event });
  await handler({ event: { ...event, subtype: 'bot_message', bot_id: 'B1' } });
  assert.equal(logged.length, 2);
  assert.equal(logged[0], event);
});
