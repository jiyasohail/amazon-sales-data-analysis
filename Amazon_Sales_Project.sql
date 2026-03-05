-- ============================================================
--  AMAZON SALES DATA ANALYSIS — SQL Server Project
--  Author  :  Javariya Sohail
--  Tool    : SQL Server Management Studio (SSMS)
--  Dataset : Amazon Sales Raw Data (2022)
--  Purpose : EDA, Schema Design, Data Cleaning & Business Insights
-- ============================================================

USE AmazonSales_Project;
GO

-- ============================================================
-- SECTION 1: EXPLORATORY DATA ANALYSIS (EDA)
-- ============================================================

-- 1.1 Preview raw data
SELECT TOP 20 * FROM Amazon_Raw_Data;

-- 1.2 Total row count
SELECT COUNT(*) AS TotalRows FROM Amazon_Raw_Data;

-- 1.3 Column-level overview
SELECT
    MIN([Date]) AS EarliestDate,
    MAX([Date]) AS LatestDate,
    MIN(amount) AS MinAmount,
    MAX(amount) AS MaxAmount,
    MIN(qty) AS MinQty,
    MAX(qty) AS MaxQty
FROM Amazon_Raw_Data;

-- 1.4 Distinct order statuses
SELECT DISTINCT status FROM Amazon_Raw_Data ORDER BY status;

-- 1.5 Distinct courier statuses
SELECT DISTINCT courier_status FROM Amazon_Raw_Data ORDER BY courier_status;

-- 1.6 Distinct categories
SELECT DISTINCT category FROM Amazon_Raw_Data ORDER BY category;

-- 1.7 Distinct fulfilment types
SELECT DISTINCT fulfilment FROM Amazon_Raw_Data ORDER BY fulfilment;

-- 1.8 B2B vs B2C split
SELECT [B2B], COUNT(*) AS OrderCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS Percentage
FROM Amazon_Raw_Data
GROUP BY [B2B];

-- 1.9 Orders per state (top 10)
SELECT TOP 10 ship_state, COUNT(*) AS OrderCount
FROM Amazon_Raw_Data
GROUP BY ship_state
ORDER BY OrderCount DESC;

-- 1.10 Null/missing value audit
SELECT
    SUM(CASE WHEN [Date] IS NULL THEN 1 ELSE 0 END) AS Null_Date,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS Null_Status,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS Null_Amount,
    SUM(CASE WHEN qty IS NULL THEN 1 ELSE 0 END) AS Null_Qty,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS Null_Category,
    SUM(CASE WHEN ship_state IS NULL THEN 1 ELSE 0 END) AS Null_ShipState,
    SUM(CASE WHEN courier_status IS NULL THEN 1 ELSE 0 END) AS Null_CourierStatus
FROM Amazon_Raw_Data;

-- 1.11 Duplicate order_id check
SELECT order_id, COUNT(*) AS DuplicateCount
FROM Amazon_Raw_Data
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;


-- ============================================================
-- SECTION 2: DATABASE SCHEMA DESIGN (NORMALISATION)
-- ============================================================

-- Drop tables if re-running
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE OrderDetails;
IF OBJECT_ID('dbo.Orders','U') IS NOT NULL DROP TABLE Orders;

-- 2.1 Orders — unique order identity
CREATE TABLE Orders (
    [index] BIGINT PRIMARY KEY,
    order_id VARCHAR(50),
    fulfilment VARCHAR(50),
    style VARCHAR(50),
    category VARCHAR(50),
    city VARCHAR(100),
    ship_state VARCHAR(100),
    B2B BIT
);

-- 2.2 OrderDetails — transactional / event data
CREATE TABLE OrderDetails (
    detail_id INT IDENTITY(1,1) PRIMARY KEY,
    [index] BIGINT,
    order_date DATE,
    status VARCHAR(50),
    courier_status VARCHAR(50),
    amount DECIMAL(10,2),
    qty INT,
    FOREIGN KEY ([index]) REFERENCES Orders([index])
);

-- ============================================================
-- SECTION 3: DATA LOADING
-- ============================================================

-- 3.1 Populate Orders
INSERT INTO Orders ([index], order_id, fulfilment, style, category, city, ship_state, B2B)
SELECT DISTINCT
    [index],
    order_id,
    fulfilment,
    style,
    category,
    ship_city,
    ship_state,
    CASE WHEN LOWER(LTRIM(RTRIM(CAST([B2B] AS VARCHAR(10))))) = 'true' THEN 1 ELSE 0 END
FROM Amazon_Raw_Data;

-- 3.2 Populate OrderDetails
INSERT INTO OrderDetails ([index], order_date, status, courier_status, amount, qty)
SELECT
    [index],
    TRY_CONVERT(DATE, [Date], 1),
    status,
    courier_status,
    TRY_CONVERT(DECIMAL(10,2), amount),
    TRY_CONVERT(INT, qty)
FROM Amazon_Raw_Data;

-- ============================================================
-- SECTION 4: POST-LOAD DATA QUALITY CHECKS
-- ============================================================

-- 4.1 Validate date range after load
SELECT
    MIN(order_date) AS EarliestOrder,
    MAX(order_date) AS LatestOrder
FROM OrderDetails;

-- 4.2 Rows with null dates (failed conversion)
SELECT COUNT(*) AS NullDateRows FROM OrderDetails WHERE order_date IS NULL;

-- 4.3 Rows with null amounts
SELECT COUNT(*) AS NullAmountRows FROM OrderDetails WHERE amount IS NULL;

-- 4.4 Rows with null qty
SELECT COUNT(*) AS NullQtyRows FROM OrderDetails WHERE qty IS NULL;

-- ============================================================
-- SECTION 5: BUSINESS INSIGHTS
-- ============================================================

--5.1 REVENUE OVERVIEW 
-- Total shipped revenue
SELECT
    SUM(amount) AS TotalShippedRevenue,
    COUNT(*) AS TotalShippedOrders,
    AVG(amount) AS AvgOrderValue
FROM OrderDetails
WHERE status LIKE '%Shipped%';

-- Revenue by order status
SELECT
    status,
    COUNT(*) AS OrderCount,
    SUM(amount) AS Revenue,
    ROUND(AVG(amount), 2) AS AvgOrderValue
FROM OrderDetails
GROUP BY status
ORDER BY Revenue DESC;

-- 5.2 CANCELLATION ANALYSIS 
-- Overall cancellation rate
SELECT
    COUNT(CASE WHEN status LIKE '%Cancel%' THEN 1 END) AS CancelledOrders,
    COUNT(*) AS TotalOrders,
    ROUND(
        COUNT(CASE WHEN status LIKE '%Cancel%' THEN 1 END) * 100.0 / COUNT(*), 2
    ) AS CancellationRate_Pct
FROM OrderDetails;

-- Cancellation rate by category
SELECT
    o.category,
    COUNT(*) AS TotalOrders,
    COUNT(CASE WHEN od.status LIKE '%Cancel%' THEN 1 END) AS CancelledOrders,
    ROUND(
        COUNT(CASE WHEN od.status LIKE '%Cancel%' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS CancellationRate_Pct
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
GROUP BY o.category
ORDER BY CancellationRate_Pct DESC;

-- ?? 5.3 CATEGORY PERFORMANCE ????????????????????????????????

-- Revenue and volume by category
SELECT
    o.category,
    COUNT(DISTINCT o.order_id)  AS UniqueOrders,
    SUM(od.qty) AS TotalUnitsSold,
    SUM(od.amount) AS TotalRevenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.category
ORDER BY TotalRevenue DESC;

-- 5.4 TIME SERIES ANALYSIS 
-- Monthly revenue trend
SELECT
    FORMAT(order_date, 'yyyy-MM') AS Month,
    COUNT(*) AS OrderCount,
    SUM(amount) AS Revenue,
    ROUND(AVG(amount), 2) AS AvgOrderValue
FROM OrderDetails
WHERE status LIKE '%Shipped%'
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY Month;

-- Week-over-week order volume
SELECT
    DATEPART(WEEK, order_date) AS WeekNumber,
    DATEPART(YEAR, order_date) AS Year,
    COUNT(*) AS OrderCount,
    SUM(amount) AS WeeklyRevenue
FROM OrderDetails
WHERE status LIKE '%Shipped%'
GROUP BY DATEPART(YEAR, order_date), DATEPART(WEEK, order_date)
ORDER BY Year, WeekNumber;

-- Day-of-week order pattern
SELECT
    DATENAME(WEEKDAY, order_date) AS DayOfWeek,
    DATEPART(WEEKDAY, order_date) AS DayNumber,
    COUNT(*) AS OrderCount,
    ROUND(AVG(amount), 2) AS AvgOrderValue
FROM OrderDetails
WHERE status LIKE '%Shipped%'
GROUP BY DATENAME(WEEKDAY, order_date), DATEPART(WEEKDAY, order_date)
ORDER BY DayNumber;

-- 5.5 GEOGRAPHIC ANALYSIS

-- Top 10 states by revenue
SELECT TOP 10
    o.ship_state,
    COUNT(DISTINCT o.order_id) AS UniqueOrders,
    SUM(od.amount) AS Revenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.ship_state
ORDER BY Revenue DESC;

-- Top 10 cities by order volume
SELECT TOP 10
    o.city,
    o.ship_state,
    COUNT(DISTINCT o.order_id)  AS UniqueOrders,
    SUM(od.amount) AS Revenue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.city, o.ship_state
ORDER BY UniqueOrders DESC;

-- 5.6 FULFILMENT ANALYSIS 
-- Revenue split: Amazon fulfilled vs Merchant fulfilled
SELECT
    o.fulfilment,
    COUNT(DISTINCT o.order_id) AS UniqueOrders,
    SUM(od.amount) AS Revenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS OrderShare_Pct
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.fulfilment;

-- Fulfilment vs courier status breakdown
SELECT
    o.fulfilment,
    od.courier_status,
    COUNT(*) AS OrderCount,
    SUM(od.amount) AS Revenue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
GROUP BY o.fulfilment, od.courier_status
ORDER BY o.fulfilment, OrderCount DESC;

-- 5.7 PRODUCT STYLE ANALYSIS 
-- Top 15 styles by revenue
SELECT TOP 15
    o.style,
    o.category,
    COUNT(DISTINCT o.order_id) AS UniqueOrders,
    SUM(od.qty) AS UnitsSold,
    SUM(od.amount) AS Revenue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.style, o.category
ORDER BY Revenue DESC;

-- ============================================================
-- SECTION 6: VIEWS (for Power BI)
-- ============================================================

-- 6.1 Monthly revenue view for trend chart
CREATE OR ALTER VIEW vw_MonthlyRevenue AS
SELECT
    FORMAT(od.order_date, 'yyyy-MM') AS Month,
    COUNT(*) AS OrderCount,
    SUM(od.amount) AS Revenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue
FROM OrderDetails od
WHERE od.status LIKE '%Shipped%'
GROUP BY FORMAT(od.order_date, 'yyyy-MM');
GO

-- 6.2 Category performance view
CREATE OR ALTER VIEW vw_CategoryPerformance AS
SELECT
    o.category,
    COUNT(DISTINCT o.order_id) AS UniqueOrders,
    SUM(od.qty) AS TotalUnitsSold,
    SUM(od.amount) AS TotalRevenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue,
    ROUND(
        SUM(od.amount) * 100.0 / SUM(SUM(od.amount)) OVER (),
        2
    )                                   AS RevenueShare_Pct
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
WHERE od.status LIKE '%Shipped%'
GROUP BY o.category;
GO

-- 6.3 Geographic view for map visual
CREATE OR ALTER VIEW vw_StateRevenue AS
SELECT
    o.ship_state,
    COUNT(DISTINCT o.order_id) AS UniqueOrders,
    SUM(od.amount) AS Revenue,
    ROUND(AVG(od.amount), 2) AS AvgOrderValue,
    COUNT(CASE WHEN od.status LIKE '%Cancel%' THEN 1 END) AS CancelledOrders
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
GROUP BY o.ship_state;
GO

-- 6.4 Fulfilment & B2B summary view
CREATE OR ALTER VIEW vw_FulfilmentSummary AS
SELECT
    o.fulfilment,
    CASE WHEN o.B2B = 1 THEN 'B2B' ELSE 'B2C' END  AS CustomerType,
    od.status,
    COUNT(*) AS OrderCount,
    SUM(od.amount) AS Revenue
FROM Orders o
JOIN OrderDetails od ON o.[index] = od.[index]
GROUP BY o.fulfilment, o.B2B, od.status;
GO

-- 6.5 Order status summary view
CREATE OR ALTER VIEW vw_OrderStatus AS
SELECT status,
    COUNT(*) AS OrderCount,
    SUM(amount) AS Revenue,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS Share_Pct
FROM OrderDetails
GROUP BY status;
GO
