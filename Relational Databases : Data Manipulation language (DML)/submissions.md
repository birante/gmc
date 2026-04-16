## Relational Databases: Data Manipulation Language (DML) - Checkpoint

```sql
/* =========================================
	Insert rows into PRODUCT
	========================================= */

INSERT INTO PRODUCT (Product_id, Product_Name, Category, Price)
VALUES ('P01', 'Samsung Galaxy S20', 'Smartphone', 3299);

INSERT INTO PRODUCT (Product_id, Product_Name, Category, Price)
VALUES ('P02', 'ASUS Notebook', 'PC', 4599);

/* =========================================
	Insert rows into CUSTOMER
	========================================= */

INSERT INTO CUSTOMER (Customer_id, Customer_Name, Customer_Tel)
VALUES ('C01', 'ALI', 71321009);

INSERT INTO CUSTOMER (Customer_id, Customer_Name, Customer_Tel)
VALUES ('C02', 'ASMA', 77345823);

/* =========================================
	Insert rows into ORDERS
	========================================= */

INSERT INTO ORDERS (Customer_id, Product_id, OrderDate, Quantity, Total_amount)
VALUES ('C01', 'P02', NULL, 2, 9198);

INSERT INTO ORDERS (Customer_id, Product_id, OrderDate, Quantity, Total_amount)
VALUES ('C02', 'P01', TO_DATE('28/05/2020', 'DD/MM/YYYY'), 1, 3299);
```

