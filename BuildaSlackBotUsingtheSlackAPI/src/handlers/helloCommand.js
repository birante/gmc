'use strict';

/**
 * Bolt `app.command('/hello')` listener.
 * Slack requires the request to be acknowledged within 3 seconds, so we ack first.
 * `/hello` -> greets the user; `/hello Alice` -> greets Alice.
 */
async function handleHelloCommand({ command, ack, respond, say, logger }) {
  await ack();

  const name = (command.text || '').trim();
  const target = name || `<@${command.user_id}>`;
  const text = `Hello ${target}! :wave: I am your Bolt bot, alive and listening in <#${command.channel_id}>.`;

  try {
    // Post publicly in the channel so everyone sees the greeting.
    await say(text);
  } catch (err) {
    // say() fails if the bot is not a member of the channel: answer privately instead.
    (logger || console).warn(`say() failed (${err.message}), falling back to respond()`);
    await respond({ response_type: 'ephemeral', text: `${text}\n_(Invite me with \`/invite @bot\` so I can post publicly here.)_` });
  }
}

module.exports = { handleHelloCommand };
