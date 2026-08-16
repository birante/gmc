# MongoDB data model for GTFS

One collection per GTFS file, indexed for the queries the trip planner
runs. Because MongoDB stores richer documents than Redis, some CSVs
collapse into fewer collections (fares → embedded on routes, etc.).

## Collections and indexes

| Collection    | Shape (excerpt)                                                | Indexes                                                       |
| ------------- | -------------------------------------------------------------- | ------------------------------------------------------------- |
| `stops`       | `{ _id, name, code, location: { type:"Point", coordinates:[lng,lat] }, parent }` | `{location: "2dsphere"}`                              |
| `routes`      | `{ _id, short_name, long_name, type, agency }`                 | `{agency: 1}`                                                 |
| `trips`       | `{ _id, route_id, service_id, headsign, direction }`           | `{route_id: 1}`, `{service_id: 1}`                            |
| `stop_times`  | `{ trip_id, stop_id, stop_sequence, departure_time, arrival_time }` | `{stop_id: 1, departure_time: 1}`, `{trip_id: 1, stop_sequence: 1}` |
| `services`    | `{ _id, days_bitmap, start_date, end_date }`                    | —                                                             |
| `transfers`   | `{ from_stop, to_stop, transfer_type, min_transfer_time }`     | `{from_stop: 1}`                                              |

## Ingestion snippet

```js
const { MongoClient } = require("mongodb");
const parse = require("csv-parse/sync").parse;
const fs    = require("fs");

const client = new MongoClient("mongodb://127.0.0.1:27017");
const csv    = (f) => parse(fs.readFileSync(f), { columns: true });

(async () => {
  await client.connect();
  const db = client.db("gtfs");

  const stops = csv("gtfs/stops.txt").map(r => ({
    _id: r.stop_id,
    name: r.stop_name,
    code: r.stop_code,
    parent: r.parent_station || null,
    location: { type: "Point", coordinates: [+r.stop_lon, +r.stop_lat] },
  }));
  await db.collection("stops").insertMany(stops, { ordered: false });
  await db.collection("stops").createIndex({ location: "2dsphere" });

  const stopTimes = csv("gtfs/stop_times.txt").map(r => ({
    trip_id:         r.trip_id,
    stop_id:         r.stop_id,
    stop_sequence:   +r.stop_sequence,
    departure_time:  r.departure_time,     // "HH:MM:SS" — sortable as string
    arrival_time:    r.arrival_time,
  }));
  // Chunk to keep the driver buffer sane on big feeds
  for (let i = 0; i < stopTimes.length; i += 10000) {
    await db.collection("stop_times").insertMany(stopTimes.slice(i, i+10000), { ordered: false });
  }
  await db.collection("stop_times").createIndex({ stop_id: 1, departure_time: 1 });
  await db.collection("stop_times").createIndex({ trip_id: 1, stop_sequence: 1 });

  await client.close();
})();
```

## Example queries

**Next 5 departures from Gare de Lyon after 14:00**

```js
db.stop_times.find(
  { stop_id: "IDFM:463640", departure_time: { $gte: "14:00:00" } },
  { _id: 0, trip_id: 1, departure_time: 1 }
).sort({ departure_time: 1 }).limit(5)
```

**Stops within 400 m of Nation**

```js
db.stops.find({
  location: { $near: {
    $geometry: { type: "Point", coordinates: [2.3960, 48.8482] },
    $maxDistance: 400,
  }}
}).limit(20)
```

**Full stop sequence for a trip**

```js
db.stop_times.find(
  { trip_id: "T-42" },
  { _id: 0, stop_id: 1, stop_sequence: 1, departure_time: 1 }
).sort({ stop_sequence: 1 })
```

**"Which trips go from A to B leaving after 14:00"** — one aggregation

```js
db.stop_times.aggregate([
  { $match: { stop_id: "A", departure_time: { $gte: "14:00:00" } } },
  { $lookup: {
      from:         "stop_times",
      let:          { trip: "$trip_id", seq: "$stop_sequence" },
      pipeline: [
        { $match: {
            $expr: { $and: [
              { $eq: [ "$trip_id", "$$trip" ] },
              { $gt: [ "$stop_sequence", "$$seq" ] },
              { $eq: [ "$stop_id", "B" ] },
            ]},
        }},
        { $limit: 1 },
      ],
      as: "arrival",
  }},
  { $unwind: "$arrival" },
  { $project: {
      _id: 0,
      trip: "$trip_id",
      departs: "$departure_time",
      arrives: "$arrival.arrival_time",
  }},
  { $sort: { departs: 1 } },
  { $limit: 5 },
])
```

The same query on Redis needs several round-trips + app-side joining —
that's the trade-off: **Redis is faster on each primitive, MongoDB is
faster on multi-step queries.**
