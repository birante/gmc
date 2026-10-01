#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Start the same topology as docker-compose.yml with native mongod/mongos
# binaries (useful when Docker is not available). Everything lives in $BASE.
#
#   config RS "cfgRS"  : 1 member  (27200)            [prod: 3 members]
#   shard  RS "shardA" : 3 members (27201, 27202, 27203)
#   shard  RS "shardB" : 3 members (27211, 27212, 27213)
#   mongos             : 27300
#
# In each shard the 3rd member is priority 0 and tagged {workload: "analytics"}
# so reporting queries can be routed to it without hurting OLTP traffic.
#
# Usage:  ./start-local.sh            # start + initiate
#         ./start-local.sh stop       # kill processes (data kept)
#         ./start-local.sh clean      # kill + delete data
# -----------------------------------------------------------------------------
set -euo pipefail
BASE="${BASE:-${TMPDIR:-/tmp}/shop-cluster}"
HOST=127.0.0.1
CACHE="--wiredTigerCacheSizeGB 0.25"

stop() { pkill -f -- "--logpath $BASE/" 2>/dev/null || true; }  # matches every mongod + mongos of this cluster
case "${1:-start}" in
  stop) stop; exit 0 ;;
  clean) stop; sleep 2; rm -rf "$BASE"; exit 0 ;;
esac

mkdir -p "$BASE"/{cfg,a1,a2,a3,b1,b2,b3}
start_mongod() { # name port rs role
  nohup mongod --$4 --replSet "$3" --port "$2" --dbpath "$BASE/$1" --bind_ip "$HOST" $CACHE \
    --logpath "$BASE/$1.log" >/dev/null 2>&1 &
}
start_mongod cfg 27200 cfgRS configsvr
start_mongod a1 27201 shardA shardsvr; start_mongod a2 27202 shardA shardsvr; start_mongod a3 27203 shardA shardsvr
start_mongod b1 27211 shardB shardsvr; start_mongod b2 27212 shardB shardsvr; start_mongod b3 27213 shardB shardsvr

wait_port() { until mongosh --quiet --port "$1" --eval 'db.runCommand({ping:1}).ok' >/dev/null 2>&1; do sleep 1; done; }
for p in 27200 27201 27202 27203 27211 27212 27213; do wait_port $p; done

mongosh --quiet --port 27200 --eval "try { rs.status() } catch (e) { rs.initiate({_id:'cfgRS', configsvr:true, members:[{_id:0, host:'$HOST:27200'}]}) }" >/dev/null
init_shard() { # rs p1 p2 p3
  mongosh --quiet --port "$2" --eval "try { rs.status() } catch (e) { rs.initiate({_id:'$1', members:[
    {_id:0, host:'$HOST:$2', priority:2, tags:{zone:'az-1'}},
    {_id:1, host:'$HOST:$3', priority:1, tags:{zone:'az-2'}},
    {_id:2, host:'$HOST:$4', priority:0, tags:{zone:'az-3', workload:'analytics'}}]}) }" >/dev/null
}
init_shard shardA 27201 27202 27203
init_shard shardB 27211 27212 27213

wait_primary() { until mongosh --quiet --port "$1" --eval 'db.hello().isWritablePrimary' 2>/dev/null | grep -q true; do sleep 1; done; }
wait_primary 27200; wait_primary 27201; wait_primary 27211

nohup mongos --configdb "cfgRS/$HOST:27200" --port 27300 --bind_ip "$HOST" --logpath "$BASE/mongos.log" >/dev/null 2>&1 &
wait_port 27300
mongosh --quiet --port 27300 --eval "
  const have = db.adminCommand({listShards:1}).shards.map(s => s._id);
  if (!have.includes('shardA')) sh.addShard('shardA/$HOST:27201,$HOST:27202,$HOST:27203');
  if (!have.includes('shardB')) sh.addShard('shardB/$HOST:27211,$HOST:27212,$HOST:27213');
  print('Shards: ' + db.adminCommand({listShards:1}).shards.map(s => s._id).join(', '));
"
echo "Cluster ready -> mongosh mongodb://$HOST:27300"
