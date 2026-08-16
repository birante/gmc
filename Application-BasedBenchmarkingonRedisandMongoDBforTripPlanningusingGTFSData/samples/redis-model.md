# Redis data model for GTFS

Each GTFS file maps to one or more Redis structures. All keys use
`<version>:<entity>:<id>` so refreshes can blue/green.

## Structures per file

| GTFS file           | Redis key                              | Type       | Content                                     |
| ------------------- | -------------------------------------- | ---------- | ------------------------------------------- |
| `stops.txt`         | `stop:<id>`                            | Hash       | `name`, `lat`, `lng`, `code`, `parent`       |
| `stops.txt` (index) | `geo:stops`                            | Geospatial | all stops indexed by lat/lng                 |
| `routes.txt`        | `route:<id>`                           | Hash       | `short_name`, `long_name`, `type`, `agency`  |
| `trips.txt`         | `trip:<id>`                            | Hash       | `route_id`, `service_id`, `headsign`, `direction` |
| `stop_times.txt`    | `stoptimes:<stop_id>`                  | Sorted Set | member = `trip_id:seq`, score = seconds-since-midnight |
| `stop_times.txt`    | `triproute:<trip_id>`                  | List       | ordered `stop_id`s of that trip             |
| `calendar.txt`      | `service:<id>`                         | Hash       | `days_bitmap`, `start_date`, `end_date`     |
| `transfers.txt`     | `transfers:<from_stop>`                | Hash       | field = `<to_stop>`, value = `type:min_time`|

## Ingestion snippet (pipelined for speed)

```js
const Redis = require("ioredis");
const parse = require("csv-parse/sync").parse;
const fs    = require("fs");

const redis = new Redis();
const csv   = (f) => parse(fs.readFileSync(f), { columns: true });

async function loadStops() {
  const p = redis.pipeline();
  for (const r of csv("gtfs/stops.txt")) {
    p.hset(`stop:${r.stop_id}`, {
      name: r.stop_name, lat: r.stop_lat, lng: r.stop_lon,
      code: r.stop_code, parent: r.parent_station,
    });
    p.geoadd("geo:stops", r.stop_lon, r.stop_lat, r.stop_id);
  }
  await p.exec();
}

async function loadStopTimes() {
  const toSec = (t) => { const [h,m,s]=t.split(":").map(Number); return h*3600+m*60+s; };
  const rows = csv("gtfs/stop_times.txt");
  let p = redis.pipeline();
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    p.zadd(`stoptimes:${r.stop_id}`, toSec(r.departure_time), `${r.trip_id}:${r.stop_sequence}`);
    p.rpush(`triproute:${r.trip_id}`, r.stop_id);
    if (i % 5000 === 0) { await p.exec(); p = redis.pipeline(); }
  }
  await p.exec();
}

(async () => { await loadStops(); await loadStopTimes(); process.exit(0); })();
```

## Example queries

```
# Next 5 departures from Gare de Lyon after 14:00 (= 50400 seconds)
ZRANGEBYSCORE stoptimes:IDFM:463640 50400 +inf LIMIT 0 5
# -> "T-42:12", "T-91:3", "T-108:7", ...

# Stops within 400 m of Nation (48.8482, 2.3960)
GEOSEARCH geo:stops FROMLONLAT 2.3960 48.8482 BYRADIUS 400 m ASC COUNT 20
# -> "IDFM:463670", "IDFM:463671", ...

# The full stop sequence for trip T-42
LRANGE triproute:T-42 0 -1
# -> [ "IDFM:463640", "IDFM:463641", "IDFM:463650", ... ]

# Look up a stop's details
HGETALL stop:IDFM:463640
# -> { "name": "Gare de Lyon", "lat": "48.8447", ... }
```

## Blue/green refresh — atomic cutover

```
1. INGEST -> write everything under prefix v2:*
2. Sanity checks (counts match feed row counts)
3. SET current_version v2
4. Readers pick the prefix from `current_version` for every request
5. Background: FLUSH old v1:* keys via SCAN + UNLINK
```
