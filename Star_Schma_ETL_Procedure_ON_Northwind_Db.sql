-- create database ETL_Northwind_Star_Schema;
USE ETL_Northwind_Star_Schema;

CREATE OR ALTER PROCEDURE star_ETL_Procedure 
AS
BEGIN
    DROP TABLE IF EXISTS DimCustomer, DimProduct, DimEmployee, DimTime, FactSales;

    -- DimCustomer
    CREATE TABLE DimCustomer (
        CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID NVARCHAR(5),
        CompanyName NVARCHAR(40),
        ContactName NVARCHAR(30),
        City NVARCHAR(15),
        Country NVARCHAR(15)
    );

    -- DimProduct
    CREATE TABLE DimProduct (
        ProductKey INT IDENTITY(1,1) PRIMARY KEY,
        ProductID INT,
        ProductName NVARCHAR(40),
        Category NVARCHAR(15),
        Supplier NVARCHAR(40)
    );

    -- DimEmployee
    CREATE TABLE DimEmployee (
        EmployeeKey INT IDENTITY(1,1) PRIMARY KEY,
        EmployeeID INT,
        FirstName NVARCHAR(10),
        LastName NVARCHAR(20),
        Title NVARCHAR(30),
        City NVARCHAR(15),
        Country NVARCHAR(15)
    );

    -- DimTime
    CREATE TABLE DimTime (
        TimeKey INT PRIMARY KEY,
        FullDate DATE,
        Day TINYINT,
        Month TINYINT,
        Quarter TINYINT,
        Year SMALLINT
    );

    -- FactSales
    CREATE TABLE FactSales (
        SalesKey INT IDENTITY(1,1) PRIMARY KEY,
        OrderID INT,
        ProductKey INT,
        CustomerKey INT,
        EmployeeKey INT,
        TimeKey INT,
        Quantity SMALLINT,
        UnitPrice MONEY,
        Discount FLOAT,
        TotalAmount AS (Quantity * UnitPrice * (1 - Discount)) PERSISTED
    );

    -- Populate DimCustomer
    INSERT INTO DimCustomer (CustomerID, CompanyName, ContactName, City, Country)
    SELECT DISTINCT CustomerID, CompanyName, ContactName, City, Country
    FROM NORTHWIND.dbo.Customers;

    -- Populate DimProduct
    INSERT INTO DimProduct (ProductID, ProductName, Category, Supplier)
    SELECT p.ProductID, p.ProductName, c.CategoryName, s.CompanyName
    FROM NORTHWIND.dbo.Products p
    JOIN NORTHWIND.dbo.Categories c ON p.CategoryID = c.CategoryID
    JOIN NORTHWIND.dbo.Suppliers s ON p.SupplierID = s.SupplierID;

    -- Populate DimEmployee
    INSERT INTO DimEmployee (EmployeeID, FirstName, LastName, Title, City, Country)
    SELECT DISTINCT EmployeeID, FirstName, LastName, Title, City, Country
    FROM NORTHWIND.dbo.Employees;

    -- Populate DimTime
    INSERT INTO DimTime (TimeKey, FullDate, Day, Month, Quarter, Year)
    SELECT DISTINCT 
        CAST(CONVERT(VARCHAR, OrderDate, 112) AS INT) AS TimeKey,
        OrderDate,
        DAY(OrderDate),
        MONTH(OrderDate),
        DATEPART(QUARTER, OrderDate),
        YEAR(OrderDate)
    FROM NORTHWIND.dbo.Orders
    WHERE OrderDate IS NOT NULL;

    -- Populate FactSales
    INSERT INTO FactSales (OrderID, ProductKey, CustomerKey, EmployeeKey, TimeKey, Quantity, UnitPrice, Discount)
    SELECT 
        od.OrderID,
        dp.ProductKey,
        dc.CustomerKey,
        de.EmployeeKey,
        CAST(CONVERT(VARCHAR, o.OrderDate, 112) AS INT) AS TimeKey,
        od.Quantity,
        od.UnitPrice,
        od.Discount
    FROM NORTHWIND.dbo.[Order Details] od
    JOIN NORTHWIND.dbo.Orders o ON od.OrderID = o.OrderID
    JOIN DimCustomer dc ON o.CustomerID = dc.CustomerID
    JOIN DimEmployee de ON o.EmployeeID = de.EmployeeID
    JOIN DimProduct dp ON od.ProductID = dp.ProductID;

    -- Foreign Keys
    ALTER TABLE FactSales
    ADD CONSTRAINT FK_FactSales_DimProduct
    FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey);

    ALTER TABLE FactSales
    ADD CONSTRAINT FK_FactSales_DimCustomer
    FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey);

    ALTER TABLE FactSales
    ADD CONSTRAINT FK_FactSales_DimEmployee
    FOREIGN KEY (EmployeeKey) REFERENCES DimEmployee(EmployeeKey);

    ALTER TABLE FactSales
    ADD CONSTRAINT FK_FactSales_DimTime
    FOREIGN KEY (TimeKey) REFERENCES DimTime(TimeKey);
END;

-- Run the procedure
EXEC star_ETL_Procedure;

-- Check results
SELECT * FROM DimCustomer;
SELECT * FROM DimEmployee;
SELECT * FROM DimProduct;
SELECT * FROM DimTime;
SELECT * FROM FactSales;
