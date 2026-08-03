// HTTP helpers built directly on the node:http request / response.
// Nothing here depends on Express or any third-party library.

const MAX_BODY_BYTES = 100 * 1024;   // reject payloads over 100 KB

// Collect the request body and parse it as JSON. Resolves with `null` for
// an empty body and rejects with a tagged error for oversized bodies or
// malformed JSON — the caller maps those to HTTP status codes.
export function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];

    req.on("data", chunk => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        req.destroy();
        reject(Object.assign(new Error("Payload too large"), { code: "PAYLOAD_TOO_LARGE" }));
        return;
      }
      chunks.push(chunk);
    });

    req.on("end", () => {
      if (chunks.length === 0) { resolve(null); return; }
      const raw = Buffer.concat(chunks).toString("utf8");
      try { resolve(JSON.parse(raw)); }
      catch { reject(Object.assign(new Error("Invalid JSON body"), { code: "BAD_JSON" })); }
    });

    req.on("error", reject);
  });
}

export function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

export function sendError(res, status, message, details) {
  const body = { error: message };
  if (details !== undefined) body.details = details;
  sendJson(res, status, body);
}

export function sendNoContent(res) {
  res.writeHead(204);
  res.end();
}
