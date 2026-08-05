-- Sample data. Meets the brief's minimum:
--   3 students, 3 instructors, 3 courses, 4 enrollments.
-- One student (Charlie) is deliberately left with no enrollments so
-- the "students not enrolled in any course" query returns a real row.

INSERT INTO instructors (instructor_id, name, department) VALUES
    (1, 'Dr. Fatou Sarr',   'Computer Science'),
    (2, 'Prof. Amadou Diop','Mathematics'),
    (3, 'Dr. Awa Fall',     'Physics');

INSERT INTO courses (course_id, title, credits, instructor_id) VALUES
    (1, 'Database Systems',   4, 1),
    (2, 'Calculus I',          3, 2),
    (3, 'Quantum Mechanics',   5, 3);

INSERT INTO students (student_id, name, email, age) VALUES
    (1, 'Alice Ba',      'alice.ba@edu.sn',   20),
    (2, 'Bob Ndiaye',    'bob.ndiaye@edu.sn', 22),
    (3, 'Charlie Sy',    'charlie.sy@edu.sn', 19);

-- Alice takes 2 courses, Bob takes 2 courses, Charlie takes none.
INSERT INTO enrollments (student_id, course_id, grade) VALUES
    (1, 1, 'A'),
    (1, 2, 'B'),
    (2, 1, 'B+'),
    (2, 3, 'C');
