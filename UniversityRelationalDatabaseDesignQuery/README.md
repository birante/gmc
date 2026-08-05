# University Relational Database — Design & Query Checkpoint

Normalised (3NF) relational schema for a university information system, sample data, and five SQL queries answering the checkpoint's questions.

## Run (SQLite, zero setup)

```bash
./run.sh
```

Uses the `sqlite3` CLI that ships with macOS. Builds a fresh `university.db`, loads `schema.sql`, inserts sample data, then executes every query in `queries.sql`.

The SQL is portable — the only line that differs across engines is the primary-key declaration (`INTEGER PRIMARY KEY AUTOINCREMENT` in SQLite, `SERIAL PRIMARY KEY` in PostgreSQL, `INT AUTO_INCREMENT PRIMARY KEY` in MySQL).

## Files

```
schema.sql          -- DDL (4 tables, keys, constraints)
data.sql            -- INSERTs: 3 students, 3 instructors, 3 courses, 4 enrollments
queries.sql         -- the 5 queries required by the brief
run.sh              -- one-shot: build DB and execute everything
expected_output.txt -- reference output of ./run.sh
```

## Schema

```
students (student_id PK)
  ├─ name         VARCHAR(120) NOT NULL
  ├─ email        VARCHAR(180) NOT NULL UNIQUE
  └─ age          INTEGER      NOT NULL, CHECK age > 17

instructors (instructor_id PK)
  ├─ name         VARCHAR(120) NOT NULL
  └─ department   VARCHAR(120) NOT NULL

courses (course_id PK)
  ├─ title            VARCHAR(160) NOT NULL UNIQUE
  ├─ credits          INTEGER      NOT NULL, CHECK credits > 0
  └─ instructor_id    INTEGER      FK → instructors(instructor_id)
                                    ON DELETE SET NULL

enrollments  (PK: (student_id, course_id))
  ├─ student_id   FK → students(student_id)    ON DELETE CASCADE
  ├─ course_id    FK → courses(course_id)      ON DELETE CASCADE
  ├─ grade        VARCHAR(2), CHECK IN ('A+','A','A-','B+','B','B-','C+','C','C-','D','F')
  └─ enrolled_at  DATE  DEFAULT CURRENT_DATE
```

### Normalisation notes (up to 3NF)

- **1NF** — every column holds an atomic value. No repeating groups (a student can be in many courses via the `enrollments` junction table, not via a multi-valued column).
- **2NF** — the only composite key is `enrollments (student_id, course_id)`. Its non-key attribute `grade` depends on the **whole** key (a grade belongs to a specific enrollment, not to a student alone or a course alone).
- **3NF** — no transitive dependencies. In particular, a course's instructor is stored as a foreign key, not as a repeated `instructor_name` / `instructor_department` on every course row.

### Constraints applied

| Table       | Constraints                                                                 |
| ----------- | --------------------------------------------------------------------------- |
| students    | `email` NOT NULL & UNIQUE, `age > 17` CHECK                                 |
| instructors | `name`, `department` NOT NULL                                               |
| courses     | `title` UNIQUE, `credits > 0` CHECK, FK to instructors with ON DELETE SET NULL |
| enrollments | composite PK (student, course), CHECK on `grade`, FKs with ON DELETE CASCADE |

### FK deletion strategy

- **Delete a course** → its enrollments are removed automatically (`ON DELETE CASCADE`), because the enrollment row loses meaning without the course.
- **Delete a student** → their enrollments cascade too — same reasoning.
- **Delete an instructor** → the courses they taught are kept but their `instructor_id` becomes `NULL` (`ON DELETE SET NULL`) — the course itself still exists, it just needs a new teacher.

## The five queries

### Q1 — students enrolled in "Database Systems"

```sql
SELECT s.student_id, s.name, s.email, s.age
FROM   students   s
JOIN   enrollments e ON e.student_id = s.student_id
JOIN   courses    c ON c.course_id  = e.course_id
WHERE  c.title = 'Database Systems'
ORDER  BY s.name;
```

Result (with the sample data):

| student_id | name       | email             | age |
| :--------: | ---------- | ----------------- | :-: |
| 1          | Alice Ba   | alice.ba@edu.sn   | 20  |
| 2          | Bob Ndiaye | bob.ndiaye@edu.sn | 22  |

### Q2 — all courses with their instructor's name

```sql
SELECT c.course_id, c.title, c.credits, i.name AS instructor
FROM   courses     c
LEFT   JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER  BY c.course_id;
```

`LEFT JOIN` (not `INNER JOIN`) so a course without an assigned instructor still shows up — instructor column would be `NULL`.

### Q3 — students not enrolled in any course

```sql
SELECT s.student_id, s.name, s.email
FROM   students s
LEFT   JOIN enrollments e ON e.student_id = s.student_id
WHERE  e.student_id IS NULL
ORDER  BY s.name;
```

Classic "anti-join" via `LEFT JOIN … IS NULL`. Returns Charlie (deliberately left with no enrollments in the sample data).

### Q4 — update a student's email

```sql
UPDATE students
SET    email = 'alice.ba@alumni.edu.sn'
WHERE  student_id = 1;
```

### Q5 — delete a course by its ID

```sql
DELETE FROM courses WHERE course_id = 3;
```

Thanks to the `ON DELETE CASCADE` on `enrollments.course_id`, the matching enrollment rows are also removed — verified by the last query in `queries.sql`, which shows that after deleting course 3 only three enrollments remain (down from four).

## Verification

Running `./run.sh` produces the sequence:

1. Q1 returns Alice + Bob.
2. Q2 lists all 3 courses with their instructors.
3. Q3 returns Charlie (the un-enrolled student).
4. Q4 changes Alice's email; before/after rows confirm the change.
5. Q5 deletes course 3, then the follow-up query confirms Bob's enrollment `(2, 3, 'C')` is gone — CASCADE worked.

Captured in `expected_output.txt` for reference.
