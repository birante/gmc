'use strict';

const fs = require('node:fs');
const path = require('node:path');

/**
 * Turn a raw Slack message event into a compact log record.
 */
function toLogRecord(event, receivedAt = new Date()) {
  return {
    receivedAt: receivedAt.toISOString(),
    channel: event.channel,
    channelType: event.channel_type,
    user: event.user || event.bot_id || null,
    subtype: event.subtype || null,
    text: event.text ?? '',
    ts: event.ts,
    threadTs: event.thread_ts || null,
  };
}

/**
 * Create a logger that writes every message both to the console and,
 * as one JSON object per line (JSON Lines), to a log file.
 */
function createMessageLogger({ logFile, console: out = console } = {}) {
  if (logFile) fs.mkdirSync(path.dirname(logFile), { recursive: true });

  return function logMessage(event) {
    const record = toLogRecord(event);
    out.log(`[message] #${record.channel} <${record.user}>: ${record.text}`);
    if (logFile) {
      try {
        fs.appendFileSync(logFile, JSON.stringify(record) + '\n');
      } catch (err) {
        out.error(`[message] could not write to ${logFile}: ${err.message}`);
      }
    }
    return record;
  };
}

module.exports = { createMessageLogger, toLogRecord };
