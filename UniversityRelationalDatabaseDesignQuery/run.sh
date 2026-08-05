#!/usr/bin/env bash
# One-shot: build a fresh SQLite DB, load schema + data, run the 5 queries.

set -euo pipefail

DB="university.db"
rm -f "$DB"

echo "==> Building schema"
sqlite3 "$DB" < schema.sql

echo "==> Inserting sample data"
sqlite3 "$DB" < data.sql

echo "==> Running queries"
sqlite3 "$DB" < queries.sql
