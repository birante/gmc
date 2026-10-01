#!/usr/bin/env bash
# Run every script in order.
#   PART1_URI   replica set used for Part 1 (transactions need a replica set)
#   CLUSTER_URI mongos of the sharded cluster used for Part 2
# Defaults match cluster/start-local.sh (mongos on 27300); Part 1 also runs
# fine against the same mongos.
set -euo pipefail
cd "$(dirname "$0")"
CLUSTER_URI="${CLUSTER_URI:-mongodb://127.0.0.1:27300}"
PART1_URI="${PART1_URI:-$CLUSTER_URI}"

echo "### Part 1 on $PART1_URI"
mongosh --quiet "$PART1_URI" 01-initial-design/schema.js
mongosh --quiet "$PART1_URI" 01-initial-design/seed.js
mongosh --quiet "$PART1_URI" 01-initial-design/queries.js

echo "### Part 2 on $CLUSTER_URI"
mongosh --quiet "$CLUSTER_URI" --eval 'var DB_NAME="shop_v1"' 01-initial-design/schema.js
mongosh --quiet "$CLUSTER_URI" --eval 'var DB_NAME="shop_v1"' 01-initial-design/seed.js
mongosh --quiet "$CLUSTER_URI" 02-refactored-design/schema.js
mongosh --quiet "$CLUSTER_URI" 02-refactored-design/sharding.js
mongosh --quiet "$CLUSTER_URI" 02-refactored-design/migrate.js
mongosh --quiet "$CLUSTER_URI" 02-refactored-design/aggregations.js
