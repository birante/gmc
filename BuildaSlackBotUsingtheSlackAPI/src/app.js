'use strict';

const { App, LogLevel } = require('@slack/bolt');
const { createMessageLogger } = require('./messageLogger');
const { handleMessage, createMessageEventHandler } = require('./handlers/messageHandler');
const { handleHelloCommand } = require('./handlers/helloCommand');

/**
 * Attach all listeners to a Bolt app (or any object with the same API).
 */
function registerListeners(app, { logMessage }) {
  // Events API: log every `message` event (message.channels subscription).
  app.event('message', createMessageEventHandler(logMessage));
  // Respond to messages (greetings, ping, help).
  app.message(handleMessage);
  // Slash command.
  app.command('/hello', handleHelloCommand);

  app.error(async (error) => {
    console.error('[bolt] unhandled error:', error);
  });
  return app;
}

/**
 * Create a configured Bolt App: Socket Mode when an app token is present,
 * otherwise HTTP mode (Events API Request URL = https://<host>/slack/events).
 */
function createApp(config) {
  const options = {
    token: config.botToken,
    signingSecret: config.signingSecret,
    logLevel: LogLevel.INFO,
  };

  if (config.socketMode) {
    options.socketMode = true;
    options.appToken = config.appToken;
  } else {
    options.port = config.port;
    options.customRoutes = [
      {
        path: '/health',
        method: ['GET'],
        handler: (req, res) => {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'ok' }));
        },
      },
    ];
  }

  const app = new App(options);
  registerListeners(app, { logMessage: createMessageLogger({ logFile: config.logFile }) });
  return app;
}

module.exports = { createApp, registerListeners };
