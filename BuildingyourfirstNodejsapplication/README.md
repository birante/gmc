# Building your first Node.js application

Three hands-on tasks covering the three flavours of Node modules:

| Task | Type of module   | File(s)                                 |
| :--: | ---------------- | --------------------------------------- |
| 1    | **Built-in**     | `fs` — read `message.txt`               |
| 2    | **Local**        | `reportGenerator.js` used by `main.js`  |
| 3    | **Third-party**  | `nodemailer` — send an email            |

## Setup

```bash
npm install          # installs nodemailer
```

Requires Node.js **≥ 14**.

## Run

```bash
npm run task1        # Task 1 — reads message.txt via fs
npm run task2        # Task 2 — uses the local reportGenerator module
npm run task3        # Task 3 — sends an email via nodemailer
# Equivalent to:
# node readFile.js
# node main.js
# node emailSender.js
```

---

## Task 1 — `fs` (built-in)

```
$ node readFile.js
Hello from the file system module!
```

Reads `message.txt` synchronously with `fs.readFileSync(path, "utf8")` and prints it. Uses `path.join(__dirname, ...)` so the script keeps working no matter where you run it from.

## Task 2 — local `reportGenerator` module

```
$ node main.js
-------- STUDENT REPORT --------
Name    : Alice Diop
Scores  : 12, 14, 8, 16, 11
Total   : 61
Average : 12.20 / 20
Status  : PASS
--------------------------------

-------- STUDENT REPORT --------
Name    : Bob Ndiaye
Scores  : 8, 6, 9, 11, 5
Total   : 39
Average : 7.80 / 20
Status  : FAIL
--------------------------------
```

`reportGenerator.js` exports a single function:

```js
module.exports = { generateReport };
```

`main.js` consumes it with `require('./reportGenerator')` and calls it twice — the passing threshold is `average >= 10` (French /20 grading). Input validation throws for non-numbers, non-strings, or empty arrays so a caller can't silently produce a bogus report.

## Task 3 — `nodemailer` (third-party)

`emailSender.js` operates in **two modes**:

### A. Real Gmail send

Set two environment variables and run:

```bash
GMAIL_USER=you@gmail.com \
GMAIL_APP_PASS='xxxx xxxx xxxx xxxx' \
MAIL_TO=someone@example.com \
node emailSender.js
```

Where the pass is a **Google app password** (not your account password) — see the [W3Schools guide](https://www.w3schools.com/nodejs/nodejs_email.asp) linked in the brief for creating one.

### B. Demo mode (default, no credentials needed)

Run with no env vars:

```
$ node emailSender.js
[emailSender] no Gmail creds found — using Ethereal test account
               user: zx7ry37zt3p4zsbf@ethereal.email
[emailSender] Message sent — id: <1d6aaa85-…@ethereal.email>
[emailSender] Accepted:    ["recipient@example.com"]
[emailSender] Rejected:    []
[emailSender] Preview URL: https://ethereal.email/message/…
```

**Ethereal** is nodemailer's official test-SMTP service — no signup, no real delivery. The script auto-creates an account via `nodemailer.createTestAccount()`, sends the message, and prints a preview URL you can open in a browser to see exactly what would arrive. This makes the demo runnable by anyone without needing Gmail credentials.

## Files

```
package.json          -- nodemailer as the only dependency
message.txt           -- the file Task 1 reads
readFile.js           -- Task 1 script
reportGenerator.js    -- Task 2 module (exports generateReport)
main.js               -- Task 2 consumer
emailSender.js        -- Task 3 script (Gmail or Ethereal fallback)
README.md
.gitignore
```

## Requirements checklist

- [x] Task 1 — Reads `message.txt` with `fs.readFileSync` and prints to console.
- [x] Task 2 — `reportGenerator.js` exports `generateReport(name, scores)`; `main.js` requires it and calls it with example data.
- [x] Task 3 — `nodemailer` installed; `emailSender.js` creates a transporter, defines mail options, calls `sendMail`, logs confirmation (message id, accepted/rejected lists, preview URL if in demo mode).
