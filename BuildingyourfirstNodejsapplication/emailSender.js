// Task 3 — third-party module: nodemailer.
//
// Two modes:
//   * Real send (Gmail) — set GMAIL_USER + GMAIL_APP_PASS env vars.
//                          The pass is a Google *app password*, not the
//                          account password (see W3Schools link in README).
//   * Demo (default)   — no env vars set: an Ethereal test account is
//                          auto-created and the "sent" message can be
//                          viewed at the printed preview URL. This is
//                          nodemailer's official way to demonstrate the
//                          flow without touching a real inbox.

const nodemailer = require("nodemailer");

async function buildTransporter() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASS;

  if (user && pass) {
    console.log(`[emailSender] using Gmail SMTP as ${user}`);
    return {
      transporter: nodemailer.createTransport({
        service: "gmail",
        auth: { user, pass },
      }),
      previewable: false,
      from: user,
    };
  }

  const testAccount = await nodemailer.createTestAccount();
  console.log("[emailSender] no Gmail creds found — using Ethereal test account");
  console.log(`               user: ${testAccount.user}`);
  return {
    transporter: nodemailer.createTransport({
      host: testAccount.smtp.host,
      port: testAccount.smtp.port,
      secure: testAccount.smtp.secure,
      auth: { user: testAccount.user, pass: testAccount.pass },
    }),
    previewable: true,
    from: testAccount.user,
  };
}

async function main() {
  const { transporter, previewable, from } = await buildTransporter();

  const mailOptions = {
    from:    `"Report Bot" <${from}>`,
    to:      process.env.MAIL_TO ?? "recipient@example.com",
    subject: "Your student report is ready",
    text:    "Hello — this is the plain-text body from the checkpoint demo.",
    html:    "<p>Hello — this is the <strong>HTML</strong> body from the checkpoint demo.</p>",
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`[emailSender] Message sent — id: ${info.messageId}`);
  console.log(`[emailSender] Accepted:    ${JSON.stringify(info.accepted)}`);
  console.log(`[emailSender] Rejected:    ${JSON.stringify(info.rejected)}`);
  if (previewable) {
    console.log(`[emailSender] Preview URL: ${nodemailer.getTestMessageUrl(info)}`);
  }
}

main().catch(err => {
  console.error("[emailSender] Failed:", err.message);
  process.exit(1);
});
