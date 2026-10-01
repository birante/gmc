# Slack Bot with Bolt for JavaScript

> Project documentation for the GoMyCode checkpoint *"Build a Slack Bot Using the Slack API"*.
> (`Readme.md` in this folder is the original assignment. This file is named `GUIDE.md` because
> macOS and Windows file systems ignore case, so a `README.md` would overwrite `Readme.md`.)

A Node.js Slack bot built with [`@slack/bolt`](https://slack.dev/bolt-js) that:

- **replies to messages** in channels it belongs to (`hello` / `hi` / `hey`, `ping`, `help`),
- **handles the `/hello` slash command** (`/hello` or `/hello Alice`),
- **logs every channel message** it receives through the **Events API** (`message.channels`) to the
  console and to `logs/messages.log` (one JSON object per line).

It runs in **HTTP mode** (Slack sends events to a public Request URL) or in **Socket Mode**
(the bot opens a WebSocket to Slack, so you don't need a public URL). Socket Mode is used
automatically when `SLACK_APP_TOKEN` is set.

---

## 1. Prerequisites

- Node.js **20.12+** (tested with Node 22). Check with `node -v`.
- A Slack workspace where you are allowed to install apps (you can create a free one at https://slack.com/get-started).
- For HTTP mode only: [ngrok](https://ngrok.com/download) (or any other way to expose a local port over HTTPS).

## 2. Create the Slack app on api.slack.com

### Option A - import the manifest (recommended, about 2 minutes)

1. Go to https://api.slack.com/apps and click **Create New App**, then choose **From a manifest**.
2. Pick your workspace and click **Next**.
3. Choose the **YAML** tab and paste the contents of one of these files:
   - `manifest.socket-mode.yml` for **Socket Mode** (easiest for local development), or
   - `manifest.yml` for **HTTP mode**. First replace both `https://YOUR-PUBLIC-URL` placeholders
     with your public URL (see [section 5](#5-http-mode-expose-the-bot-with-ngrok)). You can also
     import it as it is and fix the URLs later.
4. Click **Next** and then **Create**.
5. **Install the app**: in the sidebar, open **Install App** (or **OAuth & Permissions**), click
   **Install to Workspace**, then click **Allow**.
6. Collect the credentials:
   - **OAuth & Permissions** → **Bot User OAuth Token** (`xoxb-...`) → `SLACK_BOT_TOKEN`
   - **Basic Information** → **App Credentials** → **Signing Secret** → `SLACK_SIGNING_SECRET`
   - *(Socket Mode only)* **Basic Information** → **App-Level Tokens** → **Generate Token and Scopes**:
     give it any name, add the scope `connections:write`, click **Generate**, and copy the `xapp-...` token → `SLACK_APP_TOKEN`

### Option B - manual configuration (what the manifest does for you)

1. https://api.slack.com/apps → **Create New App** → **From scratch** → name it and pick your workspace.
2. **OAuth & Permissions** → **Scopes** → **Bot Token Scopes**: add `chat:write`, `channels:history` and `commands`.
3. *(Socket Mode)* **Socket Mode** → turn on **Enable Socket Mode**, and create the app-level token
   with `connections:write` when Slack prompts you.
4. **Event Subscriptions** → turn on **Enable Events**.
   - HTTP mode: set **Request URL** to `https://<your-public-host>/slack/events`. The bot must be running so Slack can verify the URL.
   - Under **Subscribe to bot events**, add `message.channels`. Click **Save Changes**.
5. **Slash Commands** → **Create New Command**: command `/hello`, Request URL
   `https://<your-public-host>/slack/events` (HTTP mode only; Socket Mode has no URL field),
   short description *Say hello to the bot*. Click **Save**.
6. **Install App** → **Install to Workspace** → **Allow**. Reinstall whenever you change scopes.
7. Collect the tokens as described in Option A, step 6.

### Invite the bot to a channel

The bot only receives `message.channels` events from **public channels it is a member of**.
In Slack, open a channel and type `/invite @gmc-bolt-bot` (or use the name you chose).

## 3. Install

```bash
cd BuildaSlackBotUsingtheSlackAPI
npm install
cp .env.example .env      # then edit .env and paste your tokens
```

| Variable               | Required | Description                                                             |
|------------------------|----------|-------------------------------------------------------------------------|
| `SLACK_BOT_TOKEN`      | yes      | Bot User OAuth Token (`xoxb-...`)                                       |
| `SLACK_SIGNING_SECRET` | yes      | Used to verify that requests come from Slack                            |
| `SLACK_APP_TOKEN`      | no       | App-level token (`xapp-...`). If set, the bot runs in **Socket Mode**   |
| `PORT`                 | no       | HTTP mode port (default `3000`)                                         |
| `MESSAGE_LOG_FILE`     | no       | Log file path (default `logs/messages.log`)                             |

`.env` is loaded with Node's built-in `process.loadEnvFile()`, so `dotenv` isn't needed. `.env` is gitignored.

## 4. Run

```bash
npm start        # node bot.js
npm run dev      # same, restarts on file changes (node --watch)
```

- **Socket Mode** (`SLACK_APP_TOKEN` set): `⚡️ Slack bot is running in Socket Mode`. That's all you need.
- **HTTP mode** (no `SLACK_APP_TOKEN`): `⚡️ Slack bot is running in HTTP mode on port 3000`.
  Slack sends events and slash commands to `POST /slack/events`. A health check is available at
  `GET /health`.

## 5. HTTP mode: expose the bot with ngrok

Slack needs a public HTTPS URL to reach your laptop.

```bash
# terminal 1
npm start                      # listens on PORT (3000)

# terminal 2
ngrok http 3000                # prints e.g. https://a1b2-c3d4.ngrok-free.app
```

Then, on https://api.slack.com/apps → your app:

1. **Event Subscriptions** → Request URL = `https://a1b2-c3d4.ngrok-free.app/slack/events`.
   It should show **Verified ✓**. Click **Save Changes**.
2. **Slash Commands** → edit `/hello` → Request URL = the same URL → **Save**.
3. Make sure **Socket Mode** is **off**. If it's on, Slack ignores the Request URLs.

The free ngrok URL changes every time you restart ngrok, so you'll need to update both URLs again.
Check `curl https://a1b2-c3d4.ngrok-free.app/health` → `{"status":"ok"}`.

## 6. Expected behaviour

In a channel the bot has been invited to:

| You type                 | Bot answers                                                          |
|--------------------------|----------------------------------------------------------------------|
| `hello` / `hi` / `hey`   | `Hey there @you! 👋`                                                  |
| `ping`                   | `pong 🏓`                                                             |
| `help`                   | A list of what the bot can do                                        |
| `/hello`                 | `Hello @you! 👋 I am your Bolt bot, alive and listening in #channel.` |
| `/hello Alice`           | `Hello Alice! 👋 ...`                                                 |
| anything else            | no reply, but the message is still **logged**                        |

- In a thread, replies go to the same thread.
- The bot ignores messages from other bots, its own messages, edits and deletions, so it never loops.
- If you run `/hello` in a channel the bot is not in, it replies with an **ephemeral** message
  that only you can see, and asks you to invite it.
- Every message event is logged:
  - console: `[message] #C0123ABCD <U0456EFGH>: hello everyone`
  - `logs/messages.log` (JSON Lines):
    ```json
    {"receivedAt":"2026-10-01T10:02:14.876Z","channel":"C0123ABCD","channelType":"channel","user":"U0456EFGH","subtype":null,"text":"hello everyone","ts":"1759312934.000100","threadTs":null}
    ```

## 7. Testing

```bash
npm test         # node --test "test/**/*.test.js"
```

The handlers are plain async functions, so the tests call them directly with mocked `say`, `ack` and
`respond`. They don't need Slack, a network connection or tokens. Covered:

- reply logic (greetings, ping, help, unrelated text, word boundaries),
- thread replies, ignoring bot messages and subtypes, `say()` failures,
- `/hello`: `ack()` is called before anything else, greeting the caller or a given name, ephemeral fallback,
- message logger: record format, JSON Lines file output, console output,
- configuration: HTTP vs Socket Mode detection, `PORT`, missing variables,
- listener wiring (`message` event, `app.message`, `/hello`).

## 8. Project structure

```
BuildaSlackBotUsingtheSlackAPI/
├── bot.js                       # Entry point: loads .env, builds config, starts the app
├── src/
│   ├── app.js                   # createApp() (HTTP / Socket Mode) + registerListeners()
│   ├── config.js                # .env loading and config validation
│   ├── messageLogger.js         # Console + logs/messages.log (JSON Lines) logger
│   └── handlers/
│       ├── messageHandler.js    # Reply logic + Events API logging listener
│       └── helloCommand.js      # /hello slash command
├── test/                        # node:test unit tests (no Slack needed)
├── manifest.yml                 # Slack app manifest - HTTP mode
├── manifest.socket-mode.yml     # Slack app manifest - Socket Mode
├── .env.example                 # Environment variables template
├── .gitignore                   # node_modules, .env, logs
├── package.json
├── Readme.md                    # Original assignment
├── GUIDE.md                     # This file
└── SUBMISSION.md                # Summary of the deliverable
```

## 9. Troubleshooting

| Symptom                                     | Fix                                                                                  |
|---------------------------------------------|--------------------------------------------------------------------------------------|
| `Missing required environment variable(s)`  | Create `.env` from `.env.example` and fill it in                                     |
| `invalid_auth` on start                     | Wrong or revoked `SLACK_BOT_TOKEN`. Copy it again from **OAuth & Permissions**       |
| Bot doesn't see messages                    | Invite it to the channel. Check that `message.channels` is subscribed. Reinstall the app after changing scopes |
| `/hello` → "dispatch_failed"                | Bot not running, wrong Request URL, or Socket Mode on/off doesn't match your `.env`  |
| Request URL not verified                    | Bot must be running and ngrok forwarding to the same `PORT`, with the path `/slack/events` |
| `not_in_channel` when replying              | Invite the bot to the channel (`/invite @gmc-bolt-bot`)                              |

## Resources

- Slack API: https://api.slack.com
- Bolt for JavaScript: https://slack.dev/bolt-js/getting-started
- Events API: https://api.slack.com/apis/connections/events-api
- App manifests: https://api.slack.com/reference/manifests
