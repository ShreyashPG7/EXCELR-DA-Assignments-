-- MySQL Assignment
-- Student Name: Shreyash Gawankar

-- USE the classicmodels database
USE classicmodels;

-- Q1a: Employees who are Sales Reps reporting to employee 1102
SELECT employeeNumber, firstName, lastName
FROM employees
WHERE jobTitle = 'Sales Rep'
AND reportsTo = 1102;

-- Q1b: Unique productLine values ending with 'cars'
SELECT DISTINCT productLine
FROM productlines
WHERE productLine LIKE '%cars';

-- Q2: Customer Segmentation based on country
SELECT customerNumber, customerName,
CASE 
    WHEN country IN ('USA', 'Canada') THEN 'North America'
    WHEN country IN ('UK', 'France', 'Germany') THEN 'Europe'
    ELSE 'Other'
END AS CustomerSegment
FROM customers;

-- Q3a: Top 10 products by total order quantity
SELECT productCode, SUM(quantityOrdered) AS totalQuantity
FROM orderdetails
GROUP BY productCode
ORDER BY totalQuantity DESC
LIMIT 10;

-- Q3b: Payment frequency analysis by month (with count > 20)
SELECT MONTHNAME(paymentDate) AS Month, COUNT(*) AS TotalPayments
FROM payments
GROUP BY Month
HAVING TotalPayments > 20
ORDER BY TotalPayments DESC;

-- Q4: Create Custom Database and Tables with constraints
CREATE DATABASE IF NOT EXISTS My_Customers_Orders;
USE My_Customers_Orders;

CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20)
);

CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    CHECK (total_amount > 0)
);

-- Q5: Top 5 countries by order count
USE classicmodels;
SELECT c.country, COUNT(o.orderNumber) AS orderCount
FROM customers c
JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.country
ORDER BY orderCount DESC
LIMIT 5;

-- Q6: Self Join to find employee and manager names in correct format
CREATE TABLE IF NOT EXISTS project (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    Gender ENUM('Male', 'Female'),
    ManagerID INT
);

INSERT INTO project (FullName, Gender, ManagerID) VALUES
('Pranaya', 'Female', NULL),
('Priyanka', 'Female', 1),
('Anurag', 'Male', 1),
('Sambit', 'Male', 1),
('Preety', 'Female', NULL),
('Rajesh', 'Male', 5),
('Hina', 'Female', 5);

SELECT m.FullName AS `Manager Name`, e.FullName AS `Emp Name`
FROM project e
LEFT JOIN project m ON e.ManagerID = m.EmployeeID;

-- Q7: Create and Alter facility table
CREATE TABLE facility (
    Facility_ID INT,
    Name VARCHAR(100),
    State VARCHAR(50),
    Country VARCHAR(50)
);

ALTER TABLE facility
MODIFY Facility_ID INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE facility
ADD COLUMN City VARCHAR(50) NOT NULL AFTER Name;

-- Q8: Create View for product category sales
USE classicmodels;

CREATE VIEW product_category_sales AS
SELECT pl.productLine,
       SUM(od.quantityOrdered * od.priceEach) AS total_sales,
       COUNT(DISTINCT o.orderNumber) AS number_of_orders
FROM productlines pl
JOIN products p ON pl.productLine = p.productLine
JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON od.orderNumber = o.orderNumber
GROUP BY pl.productLine;

SELECT * FROM product_category_sales;

-- Q9: Stored Procedure Get_country_payments
DELIMITER //
CREATE PROCEDURE Get_country_payments(IN in_year INT, IN in_country VARCHAR(50))
BEGIN
    SELECT YEAR(p.paymentDate) AS year,
           c.country,
           FORMAT(SUM(p.amount)/1000, 0) AS total_amount_K
    FROM customers c
    JOIN payments p ON c.customerNumber = p.customerNumber
    WHERE YEAR(p.paymentDate) = in_year
    AND c.country = in_country
    GROUP BY year, c.country;
END //
DELIMITER ;

CALL Get_country_payments(2003, 'France');

-- Q10a: Rank customers by order frequency
SELECT c.customerNumber, COUNT(o.orderNumber) AS order_count,
       RANK() OVER (ORDER BY COUNT(o.orderNumber) DESC) AS customer_rank
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerNumber;

-- Q10b: Year, Month-wise orders count with YoY change
SELECT YEAR(orderDate) AS year, MONTHNAME(orderDate) AS month,
       COUNT(orderNumber) AS order_count,
       ROUND((COUNT(orderNumber) - LAG(COUNT(orderNumber)) OVER (PARTITION BY MONTH(orderDate) ORDER BY YEAR(orderDate))) * 100 / LAG(COUNT(orderNumber)) OVER (PARTITION BY MONTH(orderDate) ORDER BY YEAR(orderDate)), 0) AS YoY_change_percent
FROM orders
GROUP BY YEAR(orderDate), MONTH(orderDate);

-- Q11: Product lines with buyPrice above average
SELECT productLine, COUNT(productCode) AS count_above_avg
FROM products
WHERE buyPrice > (SELECT AVG(buyPrice) FROM products)
GROUP BY productLine;

-- Q12: Error handling stored procedure
CREATE TABLE Emp_EH (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(50),
    EmailAddress VARCHAR(100)
);

DELIMITER //
CREATE PROCEDURE AddEmpEH(IN p_EmpID INT, IN p_EmpName VARCHAR(50), IN p_Email VARCHAR(100))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Error occurred';
    END;

    INSERT INTO Emp_EH (EmpID, EmpName, EmailAddress)
    VALUES (p_EmpID, p_EmpName, p_Email);
END //
DELIMITER ;

-- Q13: Trigger to correct negative working hours
CREATE TABLE Emp_BIT (
    Name VARCHAR(50),
    Occupation VARCHAR(50),
    Working_date DATE,
    Working_hours INT
);
INSERT INTO Emp_BIT (Name, Occupation, Working_date, Working_hours) VALUES
('Robin', 'Scientist', '2020-10-04', -12),
('Marco', 'Doctor', '2020-10-04', -14),
('Peter', 'Actor', '2020-10-04', 13);

DELIMITER //
CREATE TRIGGER before_insert_working_hours
BEFORE INSERT ON Emp_BIT
FOR EACH ROW
BEGIN
    IF NEW.Working_hours < 0 THEN
        SET NEW.Working_hours = -NEW.Working_hours;
    END IF;
END //
DELIMITER ;

SELECT * FROM Emp_BIT;
