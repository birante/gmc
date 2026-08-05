#!/usr/bin/env bash
# One-shot runner. Requires:
#   * mongosh in PATH
#   * a MongoDB reachable at the URI below (defaults to localhost:27017)
# Set MONGO_URI to point elsewhere if needed.

set -euo pipefail

MONGO_URI="${MONGO_URI:-mongodb://127.0.0.1:27017/contact}"

echo "==> mongosh $MONGO_URI < contact.js"
mongosh --quiet "$MONGO_URI" contact.js
