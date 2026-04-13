# Entity-Relationship Model - Gym Management

## 1) Entities and Attributes

### GYMNASIUM
- `gym_id` (PK)
- `name` (unique)
- `address`
- `phone`

### MEMBER
- `member_id` (PK, unique identifier)
- `last_name`
- `first_name`
- `address`
- `date_of_birth`
- `gender`
- `gym_id` (FK -> GYMNASIUM.gym_id)

### SESSION
- `session_id` (PK)
- `sport_type`
- `schedule` (date/time)
- `max_capacity` (default 20, must be <= 20)
- `gym_id` (FK -> GYMNASIUM.gym_id)

### COACH
- `coach_id` (PK)
- `last_name`
- `first_name`
- `age`
- `specialty`

### REGISTRATION (associative entity MEMBER <-> SESSION)
- `member_id` (PK, FK -> MEMBER.member_id)
- `session_id` (PK, FK -> SESSION.session_id)
- `registration_date`

### SESSION_COACH (associative entity SESSION <-> COACH)
- `session_id` (PK, FK -> SESSION.session_id)
- `coach_id` (PK, FK -> COACH.coach_id)

---

## 2) Relationships and Cardinalities

### GYMNASIUM - MEMBER
- One gymnasium has `0..N` members.
- One member belongs to exactly `1..1` gymnasium.

### GYMNASIUM - SESSION
- One gymnasium offers `0..N` sessions.
- One session belongs to exactly `1..1` gymnasium.

### MEMBER - SESSION (via REGISTRATION)
- One member registers for `0..N` sessions.
- One session contains `0..20` members.
- Constraint: do not allow more than 20 registrations per session.

### SESSION - COACH (via SESSION_COACH)
- One session is led by `1..2` coaches.
- One coach can lead `0..N` sessions.

---

## 3) Business Rules / Constraints

1. `MEMBER.member_id` is unique.
2. A member can only attend sessions where they are registered.
3. `SESSION.max_capacity <= 20`.
4. Number of rows in `REGISTRATION` per session must be <= 20.
5. Number of rows in `SESSION_COACH` per session must be between 1 and 2.
6. A member is attached to one gymnasium.

---

## 4) Relational Model (Final Tables)

- `GYMNASIUM(gym_id PK, name UNIQUE, address, phone)`
- `MEMBER(member_id PK, last_name, first_name, address, date_of_birth, gender, gym_id FK)`
- `SESSION(session_id PK, sport_type, schedule, max_capacity, gym_id FK)`
- `COACH(coach_id PK, last_name, first_name, age, specialty)`
- `REGISTRATION(member_id PK/FK, session_id PK/FK, registration_date)`
- `SESSION_COACH(session_id PK/FK, coach_id PK/FK)`

---

## 5) Diagram Guide (for Lucidchart / Draw.io)

Create 6 blocks (entities) and connect them like this:

- `GYMNASIUM 1 ---- N MEMBER`
- `GYMNASIUM 1 ---- N SESSION`
- `MEMBER N ---- N SESSION` via `REGISTRATION`
- `SESSION N ---- N COACH` via `SESSION_COACH`

Add labels on links:

- SESSION side with MEMBER: `0..20`
- COACH side with SESSION: `1..2`

This structure matches the statement and is ready to be implemented in SQL.
