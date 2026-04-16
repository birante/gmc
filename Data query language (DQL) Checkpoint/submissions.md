## Data Query Language (DQL) - Checkpoint

```sql
-- 1. Display all the data of customers
SELECT *
FROM CUSTOMER;

-- 2. Display the product_name and category for products which their price is between 5000 and 10000
SELECT ProductName, Category
FROM PRODUCT
WHERE Price BETWEEN 5000 AND 10000;

-- 3. Display all the data of products sorted in descending order of price
SELECT *
FROM PRODUCT
ORDER BY Price DESC;

-- 4. Display the total number of orders, the average amount, the highest total amount and the lower total amount
SELECT COUNT(*) AS Total_Orders,
			 AVG(TotalAmount) AS Average_Amount,
			 MAX(TotalAmount) AS Highest_Total_Amount,
			 MIN(TotalAmount) AS Lowest_Total_Amount
FROM ORDERS;

-- 5. For each product_id, display the number of orders
SELECT ProductID,
			 COUNT(*) AS Number_Of_Orders
FROM ORDERS
GROUP BY ProductID;

-- 6. Display the customer_id which has more than 2 orders
SELECT CustomerID,
			 COUNT(*) AS Number_Of_Orders
FROM ORDERS
GROUP BY CustomerID
HAVING COUNT(*) > 2;

-- 7. For each month of the 2020 year, display the number of orders
SELECT TO_CHAR(OrderDate, 'MM') AS Month,
			 COUNT(*) AS Number_Of_Orders
FROM ORDERS
WHERE EXTRACT(YEAR FROM OrderDate) = 2020
GROUP BY TO_CHAR(OrderDate, 'MM')
ORDER BY Month;

-- 8. For each order, display the product_name, the customer_name and the date of the order
SELECT p.ProductName,
			 c.CustomerName,
			 o.OrderDate
FROM ORDERS o
JOIN PRODUCT p ON o.ProductID = p.ProductID
JOIN CUSTOMER c ON o.CustomerID = c.CustomerID;

-- 9. Display all the orders made three months ago
SELECT *
FROM ORDERS
WHERE OrderDate >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -3)
	AND OrderDate < ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -2);

-- 10. Display customers (customer_id) who have never ordered a product
SELECT CustomerID
FROM CUSTOMER c
WHERE NOT EXISTS (
		SELECT 1
		FROM ORDERS o
		WHERE o.CustomerID = c.CustomerID
);
```

