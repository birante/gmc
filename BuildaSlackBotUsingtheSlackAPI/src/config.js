'use strict';

const path = require('node:path');

/**
 * Load variables from a local .env file (if it exists) using Node's built-in
 * loader, so no extra dependency (dotenv) is needed.
 */
function loadEnvFile(file = path.join(__dirname, '..', '.env')) {
  try {
    process.loadEnvFile(file);
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
  }
}

/**
 * Build the runtime configuration from an env object.
 * Socket Mode is used automatically when SLACK_APP_TOKEN is provided.
 */
function getConfig(env = process.env) {
  const socketMode = Boolean(env.SLACK_APP_TOKEN && env.SLACK_APP_TOKEN.trim());
  const config = {
    botToken: env.SLACK_BOT_TOKEN,
    signingSecret: env.SLACK_SIGNING_SECRET,
    appToken: socketMode ? env.SLACK_APP_TOKEN.trim() : undefined,
    socketMode,
    port: Number.parseInt(env.PORT, 10) || 3000,
    logFile: env.MESSAGE_LOG_FILE || path.join(__dirname, '..', 'logs', 'messages.log'),
  };

  const missing = [];
  if (!config.botToken) missing.push('SLACK_BOT_TOKEN');
  if (!config.signingSecret) missing.push('SLACK_SIGNING_SECRET');
  if (missing.length) {
    throw new Error(
      `Missing required environment variable(s): ${missing.join(', ')}. ` +
        'Copy .env.example to .env and fill in the values from https://api.slack.com/apps.'
    );
  }
  return config;
}

module.exports = { loadEnvFile, getConfig };
