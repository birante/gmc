-- The five queries requested by the brief, in order.
-- Run with:
--   sqlite3 university.db < queries.sql

-- SQLite enforces FK constraints only when this pragma is on, and only
-- for the CURRENT connection. Every script that mutates data across FK
-- boundaries must re-enable it.
PRAGMA foreign_keys = ON;

.headers on
.mode column
.width 12 20 22 6

------------------------------------------------------------------
-- Q1. Students enrolled in "Database Systems"
------------------------------------------------------------------
SELECT '-- Q1 --' AS marker;
SELECT s.student_id, s.name, s.email, s.age
FROM   students   s
JOIN   enrollments e ON e.student_id = s.student_id
JOIN   courses    c ON c.course_id  = e.course_id
WHERE  c.title = 'Database Systems'
ORDER  BY s.name;

------------------------------------------------------------------
-- Q2. All courses with their instructors' names
------------------------------------------------------------------
SELECT '-- Q2 --' AS marker;
SELECT c.course_id,
       c.title,
       c.credits,
       i.name AS instructor
FROM   courses     c
LEFT   JOIN instructors i ON i.instructor_id = c.instructor_id
ORDER  BY c.course_id;

------------------------------------------------------------------
-- Q3. Students not enrolled in ANY course
------------------------------------------------------------------
SELECT '-- Q3 --' AS marker;
SELECT s.student_id, s.name, s.email
FROM   students s
LEFT   JOIN enrollments e ON e.student_id = s.student_id
WHERE  e.student_id IS NULL
ORDER  BY s.name;

------------------------------------------------------------------
-- Q4. Update a student's email address
------------------------------------------------------------------
SELECT '-- Q4 (before) --' AS marker;
SELECT student_id, name, email FROM students WHERE student_id = 1;

UPDATE students
SET    email = 'alice.ba@alumni.edu.sn'
WHERE  student_id = 1;

SELECT '-- Q4 (after)  --' AS marker;
SELECT student_id, name, email FROM students WHERE student_id = 1;

------------------------------------------------------------------
-- Q5. Delete a course by its ID
------------------------------------------------------------------
SELECT '-- Q5 (before) --' AS marker;
SELECT course_id, title FROM courses ORDER BY course_id;

DELETE FROM courses WHERE course_id = 3;

SELECT '-- Q5 (after)  --' AS marker;
SELECT course_id, title FROM courses ORDER BY course_id;

-- Thanks to the ON DELETE CASCADE on enrollments.course_id, any
-- enrollment referencing the deleted course is removed automatically.
SELECT '-- enrollments after Q5 --' AS marker;
SELECT student_id, course_id, grade FROM enrollments ORDER BY student_id, course_id;
