# Slack Bot Checkpoint — Bolt for JavaScript

A simple Slack bot built with **Node.js** and **Bolt for JavaScript** that:

- Responds to the `/hello` slash command with a friendly greeting
- Replies when it is mentioned (`@your-bot`)
- Logs every message it receives from channels it belongs to

## Project structure

```text
CheckpointTypeScriptFundamentals/
├── bot.js              # bot logic (slash command, message logger, app_mention)
├── package.json        # ESM module, scripts, dependencies
├── .env.example        # template for the required environment variables
└── .gitignore
```

## Prerequisites

- Node.js 18+ ([nodejs.org](https://nodejs.org))
- A Slack workspace where you can install apps

## Step 1 — Create your Slack app

1. Go to <https://api.slack.com/apps> and click **Create New App → From scratch**.
2. **OAuth & Permissions** → add these Bot Token Scopes:
   - `chat:write`
   - `channels:history`
   - `app_mentions:read`
   - `commands`
3. **Slash Commands** → **Create New Command**:
   - Command: `/hello`
   - Short description: `Say hi`
   - (Request URL can stay empty when using Socket Mode.)
4. **Socket Mode** → toggle **ON**. When prompted, generate an
   **App-Level Token** with the scope `connections:write` — this is the
   `xapp-…` token.
5. **Event Subscriptions** → toggle **ON**, then under
   *Subscribe to bot events* add:
   - `message.channels`
   - `app_mention`
6. **Install App** to your workspace and copy the **Bot User OAuth Token**
   (`xoxb-…`).

## Step 2 — Configure environment variables

```bash
cp .env.example .env
```

Then edit `.env` and paste in your two tokens:

```env
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
```

> ⚠️ Never commit `.env` — it's already in `.gitignore`. If you accidentally
> commit a token, **regenerate it immediately** in the Slack app settings.

## Step 3 — Install and run

```bash
npm install
npm start
```

You should see:

```
⚡️ Bolt app is running (Socket Mode)
```

## Step 4 — Test the bot

1. In Slack, invite the bot into a channel: `/invite @your-bot-name`
2. Type `/hello` in that channel — the bot replies with a greeting.
3. Mention the bot: `@your-bot-name hi` — it replies to you.
4. Type any message in the channel — check your terminal, the bot logs it.

## How it works

- `app.command("/hello", ...)` handles the slash command. `ack()` acknowledges
  the request within Slack's 3-second window; `respond()` posts the reply.
- `app.message(...)` fires on every user message. Messages with a `subtype`
  (e.g. bot messages, joins) are ignored to avoid feedback loops.
- `app.event("app_mention", ...)` fires whenever someone `@mentions` the bot.
- Socket Mode keeps a WebSocket open to Slack, so **no public URL / ngrok
  is required** for local development.

## Switching to HTTP mode (optional)

If you'd rather use the Events API over HTTP (needs a public URL, e.g. ngrok):

1. Turn Socket Mode **off** in the Slack app dashboard.
2. Add `SLACK_SIGNING_SECRET` to `.env`.
3. In `bot.js`, replace the `App` config with:

   ```js
   const app = new App({
     token: process.env.SLACK_BOT_TOKEN,
     signingSecret: process.env.SLACK_SIGNING_SECRET,
   });
   ```

4. Expose port 3000: `ngrok http 3000`
5. Paste the HTTPS URL + `/slack/events` into **Event Subscriptions** →
   *Request URL*, and the same base URL + `/slack/events` into the slash
   command's *Request URL*.

## Resources

- [Slack API Documentation](https://api.slack.com/)
- [Bolt for JavaScript — Getting Started](https://tools.slack.dev/bolt-js/getting-started)
- [Slack Events API Guide](https://api.slack.com/apis/events-api)
