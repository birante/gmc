# DLoader — Migration of Data from SQL to NoSQL Databases

Written analysis of the nine questions in the checkpoint. Full write-up in
[`analysis.md`](./analysis.md).

## At a glance

| Question                        | Answer summary                                                              |
| ------------------------------- | --------------------------------------------------------------------------- |
| Data migration                  | Moving data between storage systems — matters for continuity, cost, risk.   |
| SQL vs NoSQL                    | Fixed schema + joins + ACID vs flexible schema + denormalization + horizontal scale. |
| DLoader role                    | ETL pipeline between an RDBMS source and a NoSQL target.                    |
| Migration steps                 | Assess → map → transform → dry-run → cutover (big-bang or CDC-based).       |
| Data transformation             | Denormalize joins → embedded docs, split large rows, type coercions.        |
| Performance                     | Batching, parallelism, target throttling, off-peak scheduling.              |
| Consistency & integrity         | Row counts, checksums, sampled diffs, dual-write during cutover.            |
| Practical plan                  | E-commerce `Customers + Orders + Order_Items` → embedded documents.         |
| Case studies                    | Craigslist → MongoDB (historical archive), Foursquare Postgres → MongoDB.    |

## A note on "DLoader"

DLoader as a named SQL-to-NoSQL migration tool doesn't appear in the widely
documented tooling landscape (unlike **AWS DMS**, **MongoDB Relational
Migrator**, **Studio 3T's SQL-to-NoSQL** feature, or **Talend**). It's most
likely a course-specific tool or a placeholder. `analysis.md` therefore:

- Treats DLoader as the tool named in the brief and describes what a
  fit-for-purpose migration tool of this kind *does*.
- Focuses on the transferable principles — the same principles apply to
  any real-world tool.
- Cites real, publicly documented case studies for the case-study section.
