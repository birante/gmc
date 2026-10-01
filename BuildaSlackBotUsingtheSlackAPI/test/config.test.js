'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { getConfig } = require('../src/config');

const base = { SLACK_BOT_TOKEN: 'xoxb-test', SLACK_SIGNING_SECRET: 'secret' };

test('HTTP mode by default with port 3000', () => {
  const c = getConfig(base);
  assert.equal(c.socketMode, false);
  assert.equal(c.port, 3000);
  assert.equal(c.appToken, undefined);
});

test('Socket Mode when SLACK_APP_TOKEN is set, custom PORT honoured', () => {
  const c = getConfig({ ...base, SLACK_APP_TOKEN: 'xapp-test', PORT: '8080' });
  assert.equal(c.socketMode, true);
  assert.equal(c.appToken, 'xapp-test');
  assert.equal(c.port, 8080);
});

test('throws a helpful error when required variables are missing', () => {
  assert.throws(() => getConfig({}), /SLACK_BOT_TOKEN, SLACK_SIGNING_SECRET/);
});
