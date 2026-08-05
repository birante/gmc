-- University information system — schema (3NF).
--
-- Enforced on every table:
--   * a PRIMARY KEY
--   * NOT NULL on required columns
--   * UNIQUE where a value must be unique (email, course title)
--   * CHECK constraints (age > 17, credits > 0, valid grade)
--   * FOREIGN KEY with ON DELETE / ON UPDATE rules
--
-- Compatible with SQLite (used for verification), PostgreSQL, and MySQL
-- with only the AUTOINCREMENT / SERIAL / AUTO_INCREMENT keyword differing.

PRAGMA foreign_keys = ON;

-- ---------------- Students ----------------
CREATE TABLE IF NOT EXISTS students (
    student_id  INTEGER      PRIMARY KEY AUTOINCREMENT,
    name        VARCHAR(120) NOT NULL,
    email       VARCHAR(180) NOT NULL UNIQUE,
    age         INTEGER      NOT NULL,
    CHECK (age > 17)
);

-- --------------- Instructors --------------
CREATE TABLE IF NOT EXISTS instructors (
    instructor_id INTEGER      PRIMARY KEY AUTOINCREMENT,
    name          VARCHAR(120) NOT NULL,
    department    VARCHAR(120) NOT NULL
);

-- ----------------- Courses ----------------
-- A course is taught by exactly one instructor; an instructor can teach
-- many courses (1-to-many). instructor_id is nullable so a course can
-- temporarily exist without an assigned instructor.
CREATE TABLE IF NOT EXISTS courses (
    course_id     INTEGER      PRIMARY KEY AUTOINCREMENT,
    title         VARCHAR(160) NOT NULL UNIQUE,
    credits       INTEGER      NOT NULL,
    instructor_id INTEGER      REFERENCES instructors(instructor_id)
                                   ON UPDATE CASCADE
                                   ON DELETE SET NULL,
    CHECK (credits > 0)
);

-- --------------- Enrollments --------------
-- Junction table between students and courses (many-to-many with a
-- grade attribute). Composite PK ensures a student cannot enrol in the
-- same course twice.
CREATE TABLE IF NOT EXISTS enrollments (
    student_id INTEGER NOT NULL REFERENCES students(student_id)
                          ON UPDATE CASCADE ON DELETE CASCADE,
    course_id  INTEGER NOT NULL REFERENCES courses(course_id)
                          ON UPDATE CASCADE ON DELETE CASCADE,
    grade      VARCHAR(2),
    enrolled_at DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (student_id, course_id),
    CHECK (grade IS NULL OR grade IN ('A+','A','A-','B+','B','B-','C+','C','C-','D','F'))
);
