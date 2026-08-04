# Node.js Checkpoint

Five guided Node.js exercises — one file per task.

| # | File                      | What it does                                           |
| - | ------------------------- | ------------------------------------------------------ |
| 1 | `hello-world.js`          | Prints `HELLO WORLD` to the console.                   |
| 2 | `server.js`               | HTTP server on port 3000 responding with `<h1>Hello Node!!!!</h1>`. |
| 3 | `file-system.js`          | Uses `fs` to write `welcome.txt` and read it back.     |
| 4 | `password-generator.js`   | Generates random passwords with `generate-password`.   |
| 5 | `email-sender.js`         | Sends an email via `nodemailer` (Gmail or Ethereal).   |

## Setup

```bash
npm install
```

Installs `generate-password` and `nodemailer`. Requires Node.js **≥ 14**.

## Run

```bash
npm run task1     # or:  node hello-world.js
npm run task2     # or:  node server.js       (visit http://localhost:3000)
npm run task3     # or:  node file-system.js
npm run task4     # or:  node password-generator.js
npm run task5     # or:  node email-sender.js
```

## Sample output

**Task 1**

```
HELLO WORLD
```

**Task 2**

```
$ node server.js
Server running at http://localhost:3000
$ curl http://localhost:3000
<h1>Hello Node!!!!</h1>
```

**Task 3**

```
Wrote /…/NodejsCheckpoint/welcome.txt
File content:
Hello Node
```

**Task 4** — 5 fresh random passwords, mixing letters/numbers/symbols and excluding lookalikes like `0/O` and `1/l/I`:

```
--- 5 random passwords ---
  ySw+Sgr5hf6[J,s@
  #3jqY@U4[S=d<eFx
  "]ZG]tB"z^v7t!N8
  9_YPc2%F5,q)U&fx
  ;&fr%(UDsD6,u{{_
```

**Task 5** — the demo runs without credentials by falling back to Ethereal (nodemailer's official test-SMTP service). No signup required, no real inbox touched.

```
[email-sender] no Gmail creds — using Ethereal test account
                user: aoswptmrds7agatv@ethereal.email
[email-sender] messageId : <…@ethereal.email>
[email-sender] accepted  : ["me@example.com"]
[email-sender] rejected  : []
[email-sender] preview   : https://ethereal.email/message/…
```

Open the preview URL in a browser to see the message exactly as it would have been delivered.

### Sending a real Gmail message

Set two environment variables (the pass is a Google **app password**, not your account password — see the [W3Schools guide](https://www.w3schools.com/nodejs/nodejs_email.asp)):

```bash
GMAIL_USER=you@gmail.com \
GMAIL_APP_PASS='xxxx xxxx xxxx xxxx' \
MAIL_TO=friend@example.com \
node email-sender.js
```

**Why env vars?** — the brief's PS warns not to leak personal info to GitHub. Keeping credentials outside the source file makes that impossible to forget.

## Files

```
package.json           -- deps + npm run task1…task5
hello-world.js         -- Task 1
server.js              -- Task 2
file-system.js         -- Task 3
password-generator.js  -- Task 4
email-sender.js        -- Task 5
welcome.txt            -- created by Task 3 (also committed as sample output)
README.md
.gitignore
```

## Requirements checklist

- [x] Task 1 — Prints "HELLO WORLD".
- [x] Task 2 — HTTP server on port 3000 replying with the exact requested HTML.
- [x] Task 3 — Creates `welcome.txt` containing "Hello Node", reads it back.
- [x] Task 4 — Uses `generate-password` to console.log passwords.
- [x] Task 5 — Uses `nodemailer` to send an email; runs out of the box via Ethereal fallback, real-Gmail via env vars.
- [x] No personal information hard-coded in any file.
