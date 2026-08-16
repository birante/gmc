# Application-Based Benchmarking — Redis vs MongoDB for GTFS Trip Planning

Written analysis of how Redis and MongoDB handle **GTFS** (General
Transit Feed Specification) data for trip planning, with concrete
modelling / query examples and a recommendation.

Full write-up in [`analysis.md`](./analysis.md). Data-model examples
in [`samples/`](./samples).

## Contents

| File                             | What it is                                                              |
| -------------------------------- | ----------------------------------------------------------------------- |
| `analysis.md`                    | The nine-section analysis the checkpoint asks for                       |
| `samples/gtfs-stop.txt`          | Sample rows from a real GTFS `stops.txt`                                |
| `samples/redis-model.md`         | How each GTFS file maps to Redis data structures + example commands     |
| `samples/mongo-model.md`         | Same, with MongoDB schemas + aggregation-pipeline query examples        |
| `samples/benchmark-outline.md`   | Which queries to benchmark and how to measure them fairly               |

## At a glance

| Question                             | Recommendation                                                        |
| ------------------------------------ | --------------------------------------------------------------------- |
| Best for **hot-path trip planning**  | **Redis** — sub-ms lookups on stops, sorted sets on time, GEOSEARCH  |
| Best for **catalogue + analytics**   | **MongoDB** — aggregation pipeline, rich indexes, cheaper storage    |
| Best for a **production trip planner** | **Redis in front of MongoDB** — MongoDB is the system of record, Redis a hot cache serving the read-heavy query traffic |
