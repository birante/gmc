'use strict';

const GREETING = /^\s*(hello|hi|hey|salut|bonjour)\b/i;
const HELP = /^\s*help\b/i;
const PING = /^\s*ping\b/i;

/**
 * Decide what (if anything) the bot should answer to a message text.
 * Pure function: easy to unit test.
 */
function buildReply(text, user) {
  if (!text) return null;
  if (GREETING.test(text)) return `Hey there <@${user}>! :wave:`;
  if (PING.test(text)) return 'pong :table_tennis_paddle_and_ball:';
  if (HELP.test(text)) {
    return [
      'Here is what I can do:',
      '• say *hello* / *hi* / *hey* and I will greet you',
      '• say *ping* and I will answer *pong*',
      '• use the `/hello` slash command',
      '• every message in channels I am in is logged by the Events API listener',
    ].join('\n');
  }
  return null;
}

/**
 * Bolt `app.message()` listener: replies to greetings / ping / help.
 * Messages with a subtype (edits, deletions, bot messages, joins...) are ignored.
 */
async function handleMessage({ message, say, logger }) {
  if (!message || message.subtype || message.bot_id) return;
  const reply = buildReply(message.text, message.user);
  if (!reply) return;
  try {
    // Reply in the thread if the message was itself in a thread.
    await say(message.thread_ts ? { text: reply, thread_ts: message.thread_ts } : reply);
  } catch (err) {
    (logger || console).error(`Failed to reply to message: ${err.message}`);
  }
}

/**
 * Build a Bolt `app.event('message')` listener that logs every message event.
 */
function createMessageEventHandler(logMessage) {
  return async function handleMessageEvent({ event }) {
    if (!event) return;
    logMessage(event);
  };
}

module.exports = { buildReply, handleMessage, createMessageEventHandler };
