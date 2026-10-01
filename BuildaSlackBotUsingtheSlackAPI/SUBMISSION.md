# Submission: Build a Slack Bot Using the Slack API

## What was delivered

| Assignment objective                       | Where it is implemented                                                                  |
|--------------------------------------------|------------------------------------------------------------------------------------------|
| Respond to messages in a Slack channel     | `src/handlers/messageHandler.js` (`handleMessage`, `buildReply`): hello/hi/hey, ping, help |
| Recognize commands like `/hello`           | `src/handlers/helloCommand.js` (`/hello`, `/hello <name>`, ack within 3 s, ephemeral fallback) |
| Log messages using the Slack Events API    | `app.event('message')` → `src/messageLogger.js`: console + `logs/messages.log` (JSON Lines) |
| Permissions `chat:write`, `channels:history` (+ `commands`) | `manifest.yml` / `manifest.socket-mode.yml`                              |
| Events API subscribed to message events    | `message.channels` bot event in both manifests                                           |
| Bot code in `bot.js`, Bolt installed       | `bot.js` entry point, `@slack/bolt` ^5.1.0 in `package.json`                             |

Extras:

- **Two connection modes**: HTTP (Events API Request URL `/slack/events`, plus `GET /health`), and
  **Socket Mode**, which turns on automatically when `SLACK_APP_TOKEN` is set.
- Modular code: handlers are pure async functions, separate from Bolt wiring (`src/app.js`).
- **17 unit tests** (`node:test`, no extra dependency) with mocked `say` / `ack` / `respond`.
  All pass (`npm test`).
- Checked end to end locally: a signed `message` event POSTed to `/slack/events` returned 200
  and was written to the console and the log file.
- No secrets in the repo: `.env`, `logs/` and `node_modules/` are gitignored. `.env.example` is provided.
- Full documentation in **`GUIDE.md`**: app setup on api.slack.com, manifest import, install, run,
  ngrok, tests, project structure, expected behaviour and troubleshooting.

> Note: the documentation is in `GUIDE.md` rather than `README.md` because the file system is
> case-insensitive, and a `README.md` would overwrite the assignment file `Readme.md`.

## What you still have to do manually

You need your own Slack account to do these steps, so they could not be automated:

1. **Create the Slack app**: https://api.slack.com/apps → *Create New App* → *From a manifest* →
   paste `manifest.socket-mode.yml` (easiest) or `manifest.yml` (HTTP mode, after replacing `YOUR-PUBLIC-URL`).
2. **Install it to your workspace** (*Install App* → *Install to Workspace* → *Allow*).
3. **Copy the tokens into `.env`** (`cp .env.example .env`):
   - `SLACK_BOT_TOKEN` (OAuth & Permissions → Bot User OAuth Token, `xoxb-...`)
   - `SLACK_SIGNING_SECRET` (Basic Information → Signing Secret)
   - `SLACK_APP_TOKEN` for Socket Mode (Basic Information → App-Level Tokens, scope `connections:write`, `xapp-...`)
4. `npm install && npm start`.
5. HTTP mode only: run `ngrok http 3000` and set
   `https://<ngrok-host>/slack/events` as the Event Subscriptions Request URL and as the `/hello` command URL.
6. **Invite the bot** to a public channel (`/invite @gmc-bolt-bot`). Then test with `hello`, `ping`, `help`,
   `/hello`, `/hello Alice`, and check `logs/messages.log`.
7. *(Optional, for the submission)* Take screenshots of the bot replying in Slack and of the log file.
