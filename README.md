
# Blinkit Sales Analysis

SQL-based analysis of Blinkit grocery sales data using MySQL.

---

## 📌 Project Overview

This project analyzes Blinkit grocery sales data using MySQL.

The project focuses on:

- Understanding the dataset
- Identifying missing and inconsistent data
- Cleaning and standardizing the data
- Validating the cleaned dataset
- Performing exploratory data analysis using SQL
- Finding useful sales patterns across products and outlets

---

## 📊 Dataset

The dataset contains **8,523 records** and **12 columns** related to grocery items and outlets.

### Main Columns

- `Item_Identifier`
- `Item_Weight`
- `Item_Fat_Content`
- `Item_Visibility`
- `Item_Type`
- `Item_MRP`
- `Outlet_Identifier`
- `Outlet_Establishment_Year`
- `Outlet_Size`
- `Outlet_Location_Type`
- `Outlet_Type`
- `Item_Outlet_Sales`

> **Note:** This dataset is an educational/fictitious dataset and does not represent actual internal Blinkit company data.

---

## 🛠️ Tools Used

- MySQL
- MySQL Workbench
- SQL
- Excel / CSV
- GitHub

---

# 🔄 Project Workflow

```text
Raw Excel Dataset
       ↓
CSV Conversion
       ↓
Raw/Staging Table
       ↓
Data Quality Checks
       ↓
Data Cleaning
       ↓
Final Analysis Table
       ↓
Exploratory Data Analysis
       ↓
Business Insights
````

---

# 🗄️ 1. Database Setup

Created a separate database for the project.

```sql
CREATE DATABASE blinkit_db;
```

Selected the database:

```sql
USE blinkit_db;
```

---

# 📋 2. Table Creation

## Raw/Staging Table

A raw table was created first so that the original CSV data could be imported without losing blank values.

```sql
CREATE TABLE blinkit_sales_raw (
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
```

## Final Analysis Table

```sql
CREATE TABLE blinkit_sales (
    Item_Identifier VARCHAR(10),
    Item_Weight DECIMAL(10,3),
    Item_Fat_Content VARCHAR(20),
    Item_Visibility DECIMAL(10,8),
    Item_Type VARCHAR(50),
    Item_MRP DECIMAL(10,3),
    Outlet_Identifier VARCHAR(10),
    Outlet_Establishment_Year INT,
    Outlet_Size VARCHAR(20),
    Outlet_Location_Type VARCHAR(20),
    Outlet_Type VARCHAR(30),
    Item_Outlet_Sales DECIMAL(12,4)
);
```

---

# 🔍 3. Data Quality Checks

The raw dataset contained:

* **8,523 total records**
* **1,463 blank Item Weight values**
* **2,410 blank Outlet Size values**

### Check Total Records and Blank Values

```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(Item_Weight = '') AS blank_item_weight,
    SUM(Outlet_Size = '') AS blank_outlet_size
FROM blinkit_sales_raw;
```

### Result

```text
Total Records       : 8523
Blank Item Weight   : 1463
Blank Outlet Size   : 2410
```

---

# 🧹 4. Data Cleaning

## 4.1 Handling Missing Item Weight

Some `Item_Weight` values were blank.

The same `Item_Identifier` appeared multiple times in the dataset, so the available weight for the same product was used to recover most missing values.

### Check Recoverable Weights

```sql
SELECT
    COUNT(*) AS missing_weight_records,
    SUM(w.item_weight IS NOT NULL) AS recoverable_records,
    SUM(w.item_weight IS NULL) AS unrecoverable_records
FROM blinkit_sales_raw r
LEFT JOIN (
    SELECT
        Item_Identifier,
        MAX(NULLIF(Item_Weight, '')) AS item_weight
    FROM blinkit_sales_raw
    WHERE Item_Weight <> ''
    GROUP BY Item_Identifier
) w
ON r.Item_Identifier = w.Item_Identifier
WHERE r.Item_Weight = '';
```

### Result

```text
Missing Weight Records : 1463
Recoverable Records    : 1459
Unrecoverable Records  : 4
```

The 4 records where the weight could not be recovered were:

```text
FDN52
FDK57
FDE52
FDQ60
```

For these remaining records, the average weight of their respective item categories was used.

---

## 4.2 Handling Missing Outlet Size

Missing `Outlet_Size` values were concentrated in three outlets:

```text
OUT010
OUT017
OUT045
```

Their outlet characteristics were checked against other outlets in the dataset.

For this educational project, these missing values were assigned the `Small` category.

---

## 4.3 Creating the Clean Dataset

The raw data was converted into the final typed table while handling missing values.

```sql
INSERT INTO blinkit_sales (
    Item_Identifier,
    Item_Weight,
    Item_Fat_Content,
    Item_Visibility,
    Item_Type,
    Item_MRP,
    Outlet_Identifier,
    Outlet_Establishment_Year,
    Outlet_Size,
    Outlet_Location_Type,
    Outlet_Type,
    Item_Outlet_Sales
)
SELECT
    r.Item_Identifier,

    CAST(
        COALESCE(
            NULLIF(r.Item_Weight, ''),
            w.item_weight,
            CASE r.Item_Type
                WHEN 'Dairy' THEN '13.426'
                WHEN 'Baking Goods' THEN '12.277'
                WHEN 'Snack Foods' THEN '12.988'
                WHEN 'Frozen Foods' THEN '12.867'
            END
        ) AS DECIMAL(10,3)
    ) AS Item_Weight,

    r.Item_Fat_Content,

    CAST(
        NULLIF(r.Item_Visibility, '')
        AS DECIMAL(10,8)
    ) AS Item_Visibility,

    r.Item_Type,

    CAST(
        NULLIF(r.Item_MRP, '')
        AS DECIMAL(10,3)
    ) AS Item_MRP,

    r.Outlet_Identifier,

    CAST(
        r.Outlet_Establishment_Year
        AS UNSIGNED
    ) AS Outlet_Establishment_Year,

    CASE
        WHEN r.Outlet_Size <> '' THEN r.Outlet_Size
        WHEN r.Outlet_Identifier IN
            ('OUT010', 'OUT017', 'OUT045')
        THEN 'Small'
    END AS Outlet_Size,

    r.Outlet_Location_Type,
    r.Outlet_Type,

    CAST(
        NULLIF(r.Item_Outlet_Sales, '')
        AS DECIMAL(12,4)
    ) AS Item_Outlet_Sales

FROM blinkit_sales_raw r

LEFT JOIN (
    SELECT
        Item_Identifier,
        MAX(NULLIF(Item_Weight, '')) AS item_weight
    FROM blinkit_sales_raw
    WHERE Item_Weight <> ''
    GROUP BY Item_Identifier
) w

ON r.Item_Identifier = w.Item_Identifier;
```

---

# ✅ 5. Final Data Validation

After cleaning, the final table was checked for remaining missing values.

```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(Item_Weight IS NULL) AS null_weight,
    SUM(Outlet_Size IS NULL) AS null_outlet_size
FROM blinkit_sales;
```

### Result

```text
Total Rows      : 8523
NULL Weight     : 0
NULL Outlet Size: 0
```

This confirmed that all records were successfully loaded into the final analysis table.

---

# 🔤 6. Standardizing Item Fat Content

The `Item_Fat_Content` column contained inconsistent values:

```text
Low Fat
Regular
LF
reg
```

`LF` was standardized to `Low Fat`, and `reg` was standardized to `Regular`.

```sql
SET SQL_SAFE_UPDATES = 0;

UPDATE blinkit_sales
SET Item_Fat_Content =
    CASE
        WHEN Item_Fat_Content = 'LF'
            THEN 'Low Fat'
        WHEN Item_Fat_Content = 'reg'
            THEN 'Regular'
        ELSE Item_Fat_Content
    END
WHERE Item_Fat_Content IN ('LF', 'reg');

SET SQL_SAFE_UPDATES = 1;
```

---

# 📈 7. Exploratory Data Analysis

## 7.1 Total Sales

### Question

What is the total sales generated across all records?

```sql
SELECT
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales
FROM blinkit_sales;
```

### Result

**Total Sales = 18,591,125.41**

---

## 7.2 Total Number of Records

```sql
SELECT
    COUNT(*) AS total_records
FROM blinkit_sales;
```

### Result

**Total Records = 8,523**

---

## 7.3 Average Sales per Record

```sql
SELECT
    ROUND(AVG(Item_Outlet_Sales), 2)
        AS avg_sales_per_record
FROM blinkit_sales;
```

### Result

**Average Sales per Record = 2,181.29**

---

# 🥦 8. Sales by Item Category

### Question

Which item categories generate the highest total sales?

```sql
SELECT
    Item_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Item_Type
ORDER BY total_sales DESC;
```

### Top Categories

| Item Type             |  Total Sales |
| --------------------- | -----------: |
| Fruits and Vegetables | 2,820,059.82 |
| Snack Foods           | 2,732,786.09 |
| Household             | 2,055,493.71 |
| Frozen Foods          | 1,825,734.79 |
| Dairy                 | 1,522,594.05 |

### Insight

**Fruits and Vegetables** generated the highest total sales among the item categories.

---

# 🏪 9. Sales by Outlet Type

### Question

Which outlet types generate the most sales?

```sql
SELECT
    Outlet_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Type
ORDER BY total_sales DESC;
```

### Result

| Outlet Type       |   Total Sales | Average Sales |
| ----------------- | ------------: | ------------: |
| Supermarket Type1 | 12,917,342.26 |      2,316.18 |
| Supermarket Type3 |  3,453,926.05 |      3,694.04 |
| Supermarket Type2 |  1,851,822.83 |      1,995.50 |
| Grocery Store     |    368,034.27 |        339.83 |

### Insight

**Supermarket Type1** generated the highest total sales.

However, **Supermarket Type3** had the highest average sales per record.

---

# 📍 10. Sales by Location Tier

### Question

How do sales vary across different outlet location tiers?

```sql
SELECT
    Outlet_Location_Type,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Location_Type
ORDER BY total_sales DESC;
```

### Result

| Location Type |  Total Sales | Average Sales |
| ------------- | -----------: | ------------: |
| Tier 3        | 7,636,752.63 |      2,279.63 |
| Tier 2        | 6,472,313.71 |      2,323.99 |
| Tier 1        | 4,482,059.07 |      1,876.91 |

### Insight

Tier 3 generated the highest total sales, while Tier 2 had the highest average sales per record.

---

# 🏪📍 11. Outlet Type + Location Analysis

```sql
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
```

### Key Findings

* **Supermarket Type1 + Tier 2** had the highest total sales.
* **Supermarket Type3 + Tier 3** had the highest average sales per record.
* **Grocery Store + Tier 3** had a very low average sales value compared with supermarket outlets.

---

# 🏆 12. Top-Selling Individual Products

### Question

Which individual products have the highest total sales?

```sql
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
```

### Top Products

| Rank | Item  | Item Type             | Total Sales |
| ---: | ----- | --------------------- | ----------: |
|    1 | FDY55 | Fruits and Vegetables |   42,661.80 |
|    2 | FDA15 | Dairy                 |   41,584.54 |
|    3 | FD720 | Fruits and Vegetables |   40,185.02 |
|    4 | FDF05 | Frozen Foods          |   36,555.75 |
|    5 | FDA04 | Frozen Foods          |   35,741.18 |
|    6 | FDK03 | Dairy                 |   34,843.98 |
|    7 | NCQ06 | Household             |   34,680.19 |
|    8 | NCQ53 | Health and Hygiene    |   34,508.41 |
|    9 | FDJ55 | Meat                  |   33,531.02 |
|   10 | FDD44 | Fruits and Vegetables |   32,723.40 |

---

# 📅 13. Outlet Establishment Year Analysis

### Question

How do sales vary based on the outlet establishment year?

```sql
SELECT
    Outlet_Establishment_Year,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Outlet_Establishment_Year
ORDER BY Outlet_Establishment_Year;
```

### Key Finding

The outlets established in **1985** had the highest total sales among the years present in the dataset.

> Total sales by establishment year should be interpreted carefully because the number of records differs between years.

---

# 🥛 14. Sales by Item Fat Content

After standardizing the values, sales were analyzed by fat content.

```sql
SELECT
    Item_Fat_Content,
    COUNT(*) AS total_records,
    ROUND(SUM(Item_Outlet_Sales), 2) AS total_sales,
    ROUND(AVG(Item_Outlet_Sales), 2) AS avg_sales
FROM blinkit_sales
GROUP BY Item_Fat_Content
ORDER BY total_sales DESC;
```

### Result

| Fat Content | Total Records |   Total Sales | Average Sales |
| ----------- | ------------: | ------------: | ------------: |
| Low Fat     |         5,517 | 11,904,094.53 |      2,157.71 |
| Regular     |         3,006 |  6,687,030.88 |      2,224.56 |

### Insight

Low Fat products generated higher total sales, while Regular products had a slightly higher average sales value per record.

---

# 🥇 15. Top Performing Outlets

### Question

Which outlets generate the highest total sales?

```sql
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
```

### Top 5 Outlets

| Rank | Outlet | Outlet Type       | Location |  Total Sales |
| ---: | ------ | ----------------- | -------- | -----------: |
|    1 | OUT027 | Supermarket Type3 | Tier 3   | 3,453,926.05 |
|    2 | OUT035 | Supermarket Type1 | Tier 2   | 2,268,122.94 |
|    3 | OUT049 | Supermarket Type1 | Tier 1   | 2,183,969.81 |
|    4 | OUT017 | Supermarket Type1 | Tier 2   | 2,167,465.29 |
|    5 | OUT013 | Supermarket Type1 | Tier 3   | 2,142,663.58 |

---

# 💡 Key Insights

Based on the SQL analysis:

1. Total sales across the dataset were **18.59 million**.
2. The dataset contains **8,523 records**.
3. **Fruits and Vegetables** had the highest total sales among item categories.
4. **Supermarket Type1** generated the highest total sales among outlet types.
5. **Supermarket Type3** had the highest average sales per record.
6. **Tier 3** generated the highest total sales by location tier.
7. **Tier 2** had the highest average sales per record by location tier.
8. **OUT027** was the highest-performing individual outlet by total sales.
9. Low Fat products generated higher total sales than Regular products.
10. Data cleaning was necessary because the raw dataset contained missing values and inconsistent categorical values.

---

# 🧠 SQL Concepts Used

This project uses the following SQL concepts:

* `CREATE DATABASE`
* `CREATE TABLE`
* `INSERT INTO ... SELECT`
* `SELECT`
* `WHERE`
* `GROUP BY`
* `ORDER BY`
* `LIMIT`
* `COUNT()`
* `SUM()`
* `AVG()`
* `ROUND()`
* `CASE`
* `COALESCE()`
* `NULLIF()`
* `CAST()`
* `DISTINCT`
* `UPDATE`
* `LEFT JOIN`
* Subqueries
* Data validation
* Data cleaning
* Aggregation

---

# 📁 Project Structure

```text
blinkit-sales-analysis/
│
├── README.md
│
├── data/
│   └── blinkit_sales.csv
│
├── SQL/
│   ├── blinkit_db.sql
│   └── blinkit_sales_analysis.sql
│
└── documentation/
    └── blinkit_sales_analysis_documentation.pdf
```

---

# ▶️ How to Run

### 1. Create the database

```sql
CREATE DATABASE blinkit_db;
USE blinkit_db;
```

### 2. Create the raw and final tables

Use the SQL scripts provided in the `SQL` folder.

### 3. Import the CSV

Import:

```text
data/blinkit_sales.csv
```

into the raw staging table.

### 4. Perform data cleaning

Run the cleaning queries from the SQL scripts.

### 5. Run the analysis queries

Execute the exploratory analysis queries to reproduce the results shown in this README.

---

# 📄 Documentation

Detailed project documentation is available in the `documentation` folder.

It includes:

* Project overview
* Dataset information
* Data quality checks
* Data cleaning process
* SQL queries
* Analysis results
* Screenshots
* Key findings

---

# 🚀 Future Scope

The project can be extended further by:

* Creating an interactive Power BI dashboard
* Adding more advanced SQL analysis
* Creating visualizations for category and outlet performance
* Performing deeper statistical analysis

---

# ⚠️ Disclaimer

This project uses an educational/fictitious Blinkit grocery sales dataset for learning and portfolio purposes.

It should not be interpreted as actual internal Blinkit business data.

---

## 👨‍💻 Project

**Blinkit Sales Analysis**

Built using **MySQL + SQL** for data cleaning, validation, and exploratory data analysis.
