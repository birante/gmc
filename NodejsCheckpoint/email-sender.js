// Task 5 — send an email with nodemailer.
//
// The brief's PS reminds us to strip personal info before pushing to
// GitHub. To make that impossible to forget, credentials are read
// exclusively from environment variables — the file contains NO
// personal email or password.
//
// Two modes:
//   Real Gmail send  -> set GMAIL_USER + GMAIL_APP_PASS (a Google *app
//                       password*, not your account password) and
//                       optionally MAIL_TO. See W3Schools guide linked
//                       in the brief.
//   Demo (default)   -> no env vars: an Ethereal test account is
//                       auto-created and the sent message can be viewed
//                       at the printed preview URL. Ethereal is the
//                       official nodemailer test-SMTP service.

const nodemailer = require("nodemailer");

async function buildTransporter() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASS;

  if (user && pass) {
    console.log(`[email-sender] using Gmail SMTP as ${user}`);
    return {
      transporter: nodemailer.createTransport({
        service: "gmail",
        auth: { user, pass },
      }),
      preview: false,
      from: user,
    };
  }

  const account = await nodemailer.createTestAccount();
  console.log("[email-sender] no Gmail creds — using Ethereal test account");
  console.log(`                user: ${account.user}`);
  return {
    transporter: nodemailer.createTransport({
      host: account.smtp.host,
      port: account.smtp.port,
      secure: account.smtp.secure,
      auth: { user: account.user, pass: account.pass },
    }),
    preview: true,
    from: account.user,
  };
}

async function main() {
  const { transporter, preview, from } = await buildTransporter();

  const info = await transporter.sendMail({
    from:    `"Node Checkpoint" <${from}>`,
    to:      process.env.MAIL_TO ?? "me@example.com",
    subject: "Hello from the Node.js checkpoint",
    text:    "This message was sent by email-sender.js — plain-text body.",
    html:    "<p>This message was sent by <code>email-sender.js</code> — HTML body.</p>",
  });

  console.log(`[email-sender] messageId : ${info.messageId}`);
  console.log(`[email-sender] accepted  : ${JSON.stringify(info.accepted)}`);
  console.log(`[email-sender] rejected  : ${JSON.stringify(info.rejected)}`);
  if (preview) {
    console.log(`[email-sender] preview   : ${nodemailer.getTestMessageUrl(info)}`);
  }
}

main().catch(err => {
  console.error("[email-sender] Failed:", err.message);
  process.exit(1);
});
