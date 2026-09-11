-- =====================================================
-- BLINKIT GROCERY SALES ANALYSIS
-- SQL Data Cleaning & Exploratory Analysis
-- =====================================================

-- =====================================================
-- 1. DATABASE SETUP
-- =====================================================

CREATE DATABASE IF NOT EXISTS blinkit_db;

USE blinkit_db;


-- =====================================================
-- 2. RAW DATA TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS blinkit_sales_raw (
    Item_Identifier VARCHAR(20),
    Item_Weight VARCHAR(20),
    Item_Fat_Content VARCHAR(20),
    Item_Visibility VARCHAR(20),
    Item_Type VARCHAR(50),
    Item_MRP VARCHAR(20),
    Outlet_Identifier VARCHAR(20),
    Outlet_Establishment_Year VARCHAR(20),
    Outlet_Size VARCHAR(20),
    Outlet_Location_Type VARCHAR(20),
    Outlet_Type VARCHAR(30),
    Item_Outlet_Sales VARCHAR(30)
);


-- =====================================================
-- 3. DATA QUALITY CHECK
-- =====================================================

SELECT COUNT(*) AS total_rows
FROM blinkit_sales_raw;


SELECT
    COUNT(*) AS total_rows,
    SUM(Item_Weight = '') AS blank_item_weight,
    SUM(Outlet_Size = '') AS blank_outlet_size
FROM blinkit_sales_raw;


-- =====================================================
-- 4. CREATE FINAL CLEAN TABLE
-- =====================================================

-- Final table was created before importing cleaned data.


-- =====================================================
-- 5. VERIFY FINAL DATA
-- =====================================================

SELECT
    COUNT(*) AS total_rows,
    SUM(Item_Weight IS NULL) AS null_weight,
    SUM(Outlet_Size IS NULL) AS null_outlet_size
FROM blinkit_sales;


-- =====================================================
-- 6. DATA STANDARDIZATION
-- =====================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE blinkit_sales
SET Item_Fat_Content =
    CASE
        WHEN Item_Fat_Content = 'LF' THEN 'Low Fat'
        WHEN Item_Fat_Content = 'reg' THEN 'Regular'
        ELSE Item_Fat_Content
    END
WHERE Item_Fat_Content IN ('LF', 'reg');

SET SQL_SAFE_UPDATES = 1;


-- =====================================================
-- 7. OVERALL KPIs
-- =====================================================

SELECT
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales
FROM blinkit_sales;


SELECT
    COUNT(*) AS total_records
FROM blinkit_sales;


SELECT
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales_per_record
FROM blinkit_sales;


-- =====================================================
-- 8. CATEGORY ANALYSIS
-- =====================================================

SELECT
    Item_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Item_Type
ORDER BY total_sales DESC;


-- =====================================================
-- 9. OUTLET TYPE ANALYSIS
-- =====================================================

SELECT
    Outlet_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Type
ORDER BY total_sales DESC;


-- =====================================================
-- 10. LOCATION ANALYSIS
-- =====================================================

SELECT
    Outlet_Location_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Location_Type
ORDER BY total_sales DESC;


-- =====================================================
-- 11. OUTLET TYPE + LOCATION ANALYSIS
-- =====================================================

SELECT
    Outlet_Type,
    Outlet_Location_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY
    Outlet_Type,
    Outlet_Location_Type
ORDER BY total_sales DESC;


-- =====================================================
-- 12. TOP 10 PRODUCTS BY SALES
-- =====================================================

SELECT
    Item_Identifier,
    Item_Type,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales
FROM blinkit_sales
GROUP BY
    Item_Identifier,
    Item_Type
ORDER BY total_sales DESC
LIMIT 10;


-- =====================================================
-- 13. SALES BY OUTLET ESTABLISHMENT YEAR
-- =====================================================

SELECT
    Outlet_Establishment_Year,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Establishment_Year
ORDER BY Outlet_Establishment_Year;


-- =====================================================
-- 14. SALES BY FAT CONTENT
-- =====================================================

SELECT
    Item_Fat_Content,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Item_Fat_Content
ORDER BY total_sales DESC;


-- =====================================================
-- 15. TOP 5 OUTLETS BY SALES
-- =====================================================

SELECT
    Outlet_Identifier,
    Outlet_Type,
    Outlet_Location_Type,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales
FROM blinkit_sales
GROUP BY
    Outlet_Identifier,
    Outlet_Type,
    Outlet_Location_Type
ORDER BY total_sales DESC
LIMIT 5;