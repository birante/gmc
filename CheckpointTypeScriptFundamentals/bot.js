import { App, LogLevel } from "@slack/bolt";
import "dotenv/config";

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  appToken: process.env.SLACK_APP_TOKEN,
  socketMode: true,
  logLevel: LogLevel.INFO,
});

app.message(async ({ message, logger }) => {
  if (message.subtype) return;
  logger.info(
    `[message] channel=${message.channel} user=${message.user} text=${message.text}`
  );
});

app.command("/hello", async ({ command, ack, respond, logger }) => {
  await ack();
  logger.info(`[/hello] user=${command.user_name} channel=${command.channel_name}`);
  await respond({
    response_type: "in_channel",
    text: `Hey <@${command.user_id}>! 👋 Welcome to the channel.`,
  });
});

app.event("app_mention", async ({ event, say, logger }) => {
  logger.info(`[app_mention] user=${event.user} text=${event.text}`);
  await say(`Hi <@${event.user}>, you mentioned me!`);
});

app.error(async (error) => {
  console.error("Bolt error:", error);
});

(async () => {
  await app.start(process.env.PORT || 3000);
  app.logger.info("⚡️ Bolt app is running (Socket Mode)");
})();
