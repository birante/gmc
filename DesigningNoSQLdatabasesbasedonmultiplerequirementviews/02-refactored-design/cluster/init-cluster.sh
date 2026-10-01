#!/usr/bin/env bash
# One-shot initialisation used by the "init" service of docker-compose.yml.
set -euo pipefail

wait_for() { until mongosh --quiet --host "$1" --eval 'db.runCommand({ping:1}).ok' >/dev/null 2>&1; do sleep 2; done; }
for h in cfg1:27019 shardA-1:27018 shardA-2:27018 shardA-3:27018 shardB-1:27018 shardB-2:27018 shardB-3:27018; do
  wait_for "$h"
done

mongosh --quiet --host cfg1:27019 --eval "
try { rs.status() } catch (e) {
  rs.initiate({ _id: 'cfgRS', configsvr: true, members: [{ _id: 0, host: 'cfg1:27019' }] })
}"

for rs in shardA shardB; do
  mongosh --quiet --host "$rs-1:27018" --eval "
  try { rs.status() } catch (e) {
    rs.initiate({ _id: '$rs', members: [
      { _id: 0, host: '$rs-1:27018', priority: 2, tags: { zone: 'az-1' } },
      { _id: 1, host: '$rs-2:27018', priority: 1, tags: { zone: 'az-2' } },
      { _id: 2, host: '$rs-3:27018', priority: 0, tags: { zone: 'az-3', workload: 'analytics' } }
    ] })
  }"
done

wait_primary() { until mongosh --quiet --host "$1" --eval 'db.hello().isWritablePrimary' 2>/dev/null | grep -q true; do sleep 2; done; }
wait_primary cfg1:27019; wait_primary shardA-1:27018; wait_primary shardB-1:27018
wait_for mongos:27017

mongosh --quiet --host mongos:27017 --eval "
const have = db.adminCommand({ listShards: 1 }).shards.map(s => s._id);
if (!have.includes('shardA')) sh.addShard('shardA/shardA-1:27018,shardA-2:27018,shardA-3:27018');
if (!have.includes('shardB')) sh.addShard('shardB/shardB-1:27018,shardB-2:27018,shardB-3:27018');
print('Shards: ' + db.adminCommand({ listShards: 1 }).shards.map(s => s._id).join(', '));
"
echo "Cluster ready -> mongosh mongodb://localhost:27017"
