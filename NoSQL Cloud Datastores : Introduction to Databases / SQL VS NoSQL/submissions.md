# Checkpoint Presentation: MongoDB vs SQL (5 Slides)

## Slide 1 - SQL Databases: What They Are and What They Do
**Main idea:** SQL databases store data in structured tables with fixed schemas.

- Data model: tables, rows, columns
- Query language: SQL (`SELECT`, `JOIN`, `GROUP BY`)
- Key strengths: ACID transactions, strong consistency, relational integrity
- Typical use cases: banking, ERP, e-commerce orders, reporting systems

**Visual suggestion:** A simple relational diagram with 3 linked tables (`Users`, `Orders`, `Products`).

---

## Slide 2 - MongoDB (NoSQL): What It Is and What It Does
**Main idea:** MongoDB stores data as flexible JSON-like documents.

- Data model: collections and documents (BSON)
- Schema flexibility: fields can vary between documents
- Key strengths: fast iteration, horizontal scaling, developer-friendly structure
- Typical use cases: content apps, IoT, real-time analytics, social platforms

**Visual suggestion:** A sample document and a collection view showing varied document fields.

---

## Slide 3 - Data Model and Query Comparison
**Main idea:** SQL is relational and normalized; MongoDB is document-based and denormalized when needed.

- SQL: normalization reduces duplication, joins combine related data
- MongoDB: embedding data reduces joins and improves read speed for some use cases
- SQL query example: `SELECT name FROM users WHERE id = 1;`
- MongoDB query example: `db.users.find({ _id: 1 }, { name: 1 })`

**Visual suggestion:** Side-by-side split: SQL table query vs MongoDB document query.

---

## Slide 4 - Performance, Scaling, and Transactions
**Main idea:** Each system is optimized for different scaling and transaction needs.

- SQL: vertical scaling is common; excellent for complex multi-table transactions
- MongoDB: built for horizontal scaling (sharding) and high write throughput
- SQL usually preferred for strict financial consistency
- MongoDB preferred for large, evolving, high-volume datasets

**Visual suggestion:** Performance and scaling chart: vertical vs horizontal scaling illustration.

---

## Slide 5 - Final Comparison and Decision Guide
**Main idea:** Choose based on your project requirements, not trends.

| Criteria | SQL | MongoDB |
|---|---|---|
| Data structure | Fixed schema | Flexible schema |
| Relationships | Strong with joins | Limited joins, often embedded |
| Transactions | Very strong (ACID) | Supported, but often used with flexible modeling |
| Scaling style | Mostly vertical | Native horizontal scaling |
| Best for | Structured, transactional systems | Fast-changing, large-scale applications |

**Conclusion sentence for presentation:**
"SQL is best when data integrity and complex relationships are critical; MongoDB is best when flexibility, speed of development, and scalability are top priorities."

**Visual suggestion:** Decision matrix with check marks per use case.
