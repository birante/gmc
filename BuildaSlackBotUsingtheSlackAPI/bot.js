'use strict';

const { loadEnvFile, getConfig } = require('./src/config');
const { createApp } = require('./src/app');

async function main() {
  loadEnvFile();

  let config;
  try {
    config = getConfig();
  } catch (err) {
    console.error(`[config] ${err.message}`);
    process.exit(1);
  }

  const app = createApp(config);

  if (config.socketMode) {
    await app.start();
    console.log('⚡️ Slack bot is running in Socket Mode');
  } else {
    await app.start(config.port);
    console.log(`⚡️ Slack bot is running in HTTP mode on port ${config.port}`);
    console.log(`   Events & slash command URL: https://<your-public-host>/slack/events`);
  }
  console.log(`   Messages are logged to ${config.logFile}`);
}

main().catch((err) => {
  console.error('Failed to start the bot:', err);
  process.exit(1);
});
