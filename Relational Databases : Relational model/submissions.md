# Relational Diagram Conversion (Hotel Database)

## 1) Relational Schema (Tables, PK, FK)

### TYPE
- Type_Id (PK)
- Type_Name

### HOTEL
- Hotel_Id (PK)
- Hotel_Name
- Type_Id (FK -> TYPE.Type_Id)

### CATEGORY
- Category_Id (PK)
- Category_Name
- Price
- Beds_Number

### ROOM
- Room_Id (PK)
- Floor
- Hotel_Id (FK -> HOTEL.Hotel_Id)
- Category_Id (FK -> CATEGORY.Category_Id)

### EMPLOYEE

- Employee_Id (PK)
- Employee_Name
- Employee_Speciality
- Hotel_Id (FK -> HOTEL.Hotel_Id)
- Leader_Id (FK -> EMPLOYEE.Employee_Id)  
	(recursive relation "leads": one leader can lead many employees)

---

## 2) Cardinality Mapping (ER -> Relational)

1. Hotel is Type (Hotel 1..1, Type 1..N)  
	 -> Put Type_Id as FK in HOTEL.

2. Hotel is composed of Room (Hotel 1..N, Room 1..1)  
	 -> Put Hotel_Id as FK in ROOM.

3. Room is of Category (Room 1..1, Category 1..N)  
	 -> Put Category_Id as FK in ROOM.

4. Employee Works in Hotel (Hotel 1..N, Employee 1..1)  
	 -> Put Hotel_Id as FK in EMPLOYEE.

5. Employee leads Employee (1..N self-relationship)  
	 -> Add Leader_Id self-FK in EMPLOYEE.

---

## 3) SQL Version (Optional, ready to execute)

```sql
CREATE TABLE TYPE (
	Type_Id INT PRIMARY KEY,
	Type_Name VARCHAR(100)
);

CREATE TABLE HOTEL (
	Hotel_Id INT PRIMARY KEY,
	Hotel_Name VARCHAR(120),
	Type_Id INT NOT NULL,
	FOREIGN KEY (Type_Id) REFERENCES TYPE(Type_Id)
);

CREATE TABLE CATEGORY (
	Category_Id INT PRIMARY KEY,
	Category_Name VARCHAR(100),
	Price DECIMAL(10,2) CHECK (Price > 0),
	Beds_Number INT CHECK (Beds_Number > 0)
);

CREATE TABLE ROOM (
	Room_Id INT PRIMARY KEY,
	Floor INT CHECK (Floor >= 0),
	Hotel_Id INT NOT NULL,
	Category_Id INT NOT NULL,
	FOREIGN KEY (Hotel_Id) REFERENCES HOTEL(Hotel_Id),
	FOREIGN KEY (Category_Id) REFERENCES CATEGORY(Category_Id)
);

CREATE TABLE EMPLOYEE (
	Employee_Id INT PRIMARY KEY,
	Employee_Name VARCHAR(120),
	Employee_Speciality VARCHAR(120),
	Hotel_Id INT NOT NULL,
	Leader_Id INT,
	CHECK (Leader_Id IS NULL OR Leader_Id <> Employee_Id),
	FOREIGN KEY (Hotel_Id) REFERENCES HOTEL(Hotel_Id),
	FOREIGN KEY (Leader_Id) REFERENCES EMPLOYEE(Employee_Id)
);
```

## 4) Dependency Order (for creation)

1. TYPE
2. HOTEL (depends on TYPE)
3. CATEGORY
4. ROOM (depends on HOTEL and CATEGORY)
5. EMPLOYEE (depends on HOTEL and EMPLOYEE)
