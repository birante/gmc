// Entry point — creates the HTTP server, delegates every request to the
// router, and listens on the configured port.

import http from "node:http";
import { route } from "./router.js";
import { sendError } from "./http.js";

const PORT = Number(process.env.PORT ?? 3000);
const HOST = process.env.HOST ?? "127.0.0.1";

export function createApp() {
  return http.createServer(async (req, res) => {
    try {
      await route(req, res);
    } catch (err) {
      console.error("[server] unhandled error:", err);
      if (!res.headersSent) sendError(res, 500, "Internal Server Error");
      else res.end();
    }
  });
}

// only auto-start when run directly (so tests can boot the server too)
if (import.meta.url === `file://${process.argv[1]}`) {
  const server = createApp();
  server.listen(PORT, HOST, () => {
    console.log(`todo-restful-api listening on http://${HOST}:${PORT}`);
  });
}
