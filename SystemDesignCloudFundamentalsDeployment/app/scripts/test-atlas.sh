#!/usr/bin/env bash
# test-atlas.sh — verifies the MERN app connects to your MongoDB Atlas
# cluster. Reads MONGO_URI interactively (invisible input), never writes
# it to disk, never puts it in your shell history.

set -euo pipefail

cd "$(dirname "$0")/.."   # -> app/

if [[ -z "${MONGO_URI:-}" ]]; then
  read -rsp "Paste your MongoDB Atlas URI (input hidden): " MONGO_URI
  echo
fi
if [[ -z "$MONGO_URI" ]]; then
  echo "MONGO_URI is empty, aborting." >&2
  exit 1
fi

export MONGO_URI PORT=3000

echo "==> starting server against Atlas…"
node server/index.js > /tmp/mern-atlas.log 2>&1 &
SERVER_PID=$!
trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

# Wait up to 20s for the server to accept connections.
for _ in $(seq 1 40); do
  if curl -sS -o /dev/null http://localhost:3000/api/health; then break; fi
  sleep 0.5
done

echo
echo "--- server log ---"
cat /tmp/mern-atlas.log
echo

echo "--- POST /api/users ---"
curl -sS -X POST http://localhost:3000/api/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Atlas Test","email":"atlas.test@example.com","role":"admin"}' || true
echo
echo "--- GET  /api/users ---"
curl -sS http://localhost:3000/api/users | head -c 400
echo

echo
echo "==> if you see the created user in the GET list, Atlas is wired up correctly."
echo "==> open http://localhost:3000 in a browser to use the UI."
echo "==> press Ctrl-C to stop the server."
wait $SERVER_PID
