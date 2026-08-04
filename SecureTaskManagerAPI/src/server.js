const { createApp } = require("./app");

const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || "127.0.0.1";

const app = createApp();
app.listen(PORT, HOST, () => {
  console.log(`secure-task-manager-api listening on http://${HOST}:${PORT}`);
  console.log(`Google OAuth: ${process.env.GOOGLE_CLIENT_ID ? "ENABLED" : "disabled (set GOOGLE_CLIENT_ID + _SECRET to enable)"}`);
});
