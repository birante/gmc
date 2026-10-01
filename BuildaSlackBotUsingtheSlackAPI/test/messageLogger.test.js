'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createMessageLogger, toLogRecord } = require('../src/messageLogger');

test('toLogRecord extracts the useful fields', () => {
  const r = toLogRecord({ channel: 'C1', channel_type: 'channel', user: 'U1', text: 'hi', ts: '1.0' }, new Date(0));
  assert.deepEqual(r, {
    receivedAt: '1970-01-01T00:00:00.000Z',
    channel: 'C1',
    channelType: 'channel',
    user: 'U1',
    subtype: null,
    text: 'hi',
    ts: '1.0',
    threadTs: null,
  });
});

test('createMessageLogger writes JSON lines to the file and to the console', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'slackbot-'));
  const logFile = path.join(dir, 'nested', 'messages.log');
  const lines = [];
  const logMessage = createMessageLogger({ logFile, console: { log: (l) => lines.push(l), error() {} } });

  logMessage({ channel: 'C1', user: 'U1', text: 'first', ts: '1.0' });
  logMessage({ channel: 'C1', user: 'U2', text: 'second', ts: '2.0' });

  const records = fs.readFileSync(logFile, 'utf8').trim().split('\n').map(JSON.parse);
  assert.equal(records.length, 2);
  assert.equal(records[1].text, 'second');
  assert.equal(lines[0], '[message] #C1 <U1>: first');
  fs.rmSync(dir, { recursive: true, force: true });
});
