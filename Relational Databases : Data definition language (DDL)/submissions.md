## Relational Databases: Data Definition Language (DDL) - Checkpoint

```sql
/* =========================================
   1) Create tables based on the model
   ========================================= */

CREATE TABLE CUSTOMER (
	CustomerID    NUMBER(5)      CONSTRAINT PK_CUSTOMER PRIMARY KEY,
	CustomerName  VARCHAR2(50)   NOT NULL,
	CustomerTel   VARCHAR2(20)   NOT NULL
);

CREATE TABLE PRODUCT (
	ProductID     NUMBER(5)      CONSTRAINT PK_PRODUCT PRIMARY KEY,
	ProductName   VARCHAR2(50)   NOT NULL,
	Price         NUMBER(10,2)   NOT NULL,
	CONSTRAINT CHK_PRODUCT_PRICE CHECK (Price > 0)
);

CREATE TABLE ORDERS (
	OrderID       NUMBER(10)     CONSTRAINT PK_ORDERS PRIMARY KEY,
	CustomerID    NUMBER(5)      NOT NULL,
	ProductID     NUMBER(5)      NOT NULL,
	Quantity      NUMBER(5)      NOT NULL,
	TotalAmount   NUMBER(12,2)   NOT NULL,
	CONSTRAINT FK_ORDERS_CUSTOMER FOREIGN KEY (CustomerID)
		REFERENCES CUSTOMER (CustomerID),
	CONSTRAINT FK_ORDERS_PRODUCT FOREIGN KEY (ProductID)
		REFERENCES PRODUCT (ProductID),
	CONSTRAINT CHK_ORDERS_QUANTITY CHECK (Quantity > 0),
	CONSTRAINT CHK_ORDERS_TOTAL CHECK (TotalAmount >= 0)
);

/* =========================================
   2) Required ALTER TABLE statements
   ========================================= */

ALTER TABLE PRODUCT
ADD Category VARCHAR2(20);

ALTER TABLE ORDERS
ADD OrderDate DATE DEFAULT SYSDATE;
```

