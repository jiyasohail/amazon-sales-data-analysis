# 🛒 Amazon Sales Data Analysis --- End-to-End SQL Project

## 📌 Project Overview

This end-to-end data analysis project explores an Amazon India sales
dataset using SQL Server (SSMS).

The project covers the full data workflow:

-   Raw data exploration (EDA)
-   Database normalization (3NF)
-   Defensive data cleaning & validation
-   Business KPI analysis
-   Creation of reporting-ready SQL views for BI integration

The objective is to answer real business questions around:

-   Revenue performance\
-   Cancellation behavior\
-   Geographic sales distribution\
-   Fulfilment efficiency\
-   B2B vs B2C segmentation

This project demonstrates production-style SQL practices rather than
isolated query exercises.

------------------------------------------------------------------------

## 🗂️ Repository Structure

amazon-sales-project/
│
├── amazon_sales_analysis.sql     # Full SQL script (EDA → Schema → Insights → Views)
├── README.md                     # Project documentation
└── powerbi/                      # (Future dashboard layer)

------------------------------------------------------------------------

## 📊 Dataset

  -----------------------------------------------------------------------
| Property    | Detail                                                                                                       |
| ----------- | ------------------------------------------------------------------------------------------------------------ |
| Source      | Amazon India Sales Dataset (Kaggle)                                                                          |
| Period      | March 2022 – June 2022                                                                                       |
| Rows        | ~128,975                                                                                                     |
| Key Columns | order_id, date, status, fulfilment, style, category, ship_city, ship_state, courier_status, qty, amount, B2B |

------------------------------------------------------------------------

## 🏗️ Database Schema (3NF Normalisation)

The raw flat file was normalized into two related tables to eliminate
redundancy and improve maintainability.

### Orders

-   index (PK)
-   order_id
-   fulfilment
-   style
-   category
-   city
-   ship_state
-   B2B (BIT)

### OrderDetails

-   detail_id (PK)
-   index (FK → Orders)
-   order_date
-   status
-   courier_status
-   amount
-   qty

**Why normalise?**\
Order identity attributes are stored once and referenced through a
foreign key, avoiding duplication and improving query clarity.

------------------------------------------------------------------------

## 🔍 Project Workflow

### 1️⃣ Exploratory Data Analysis (EDA)

-   Row count verification
-   Date range validation
-   Distinct value analysis
-   B2B vs B2C split analysis
-   Top states by order volume
-   Full null audit
-   Duplicate order_id detection

Defensive casting using TRY_CONVERT was applied to date, amount, and
quantity fields.

------------------------------------------------------------------------

### 2️⃣ Schema Design & Data Loading

-   Designed 3NF schema with primary and foreign keys
-   Cast B2B to BIT type
-   Inserted distinct records into Orders
-   Inserted transactional data into OrderDetails
-   Applied safe type conversion using TRY_CONVERT

------------------------------------------------------------------------

### 3️⃣ Post-Load Validation

-   Null checks repeated
-   Date range validated
-   Row reconciliation performed

------------------------------------------------------------------------

## 📈 Business Questions Answered

-   Total shipped revenue & AOV
-   Cancellation rate overall & by category
-   Highest revenue categories
-   Month-over-month revenue trend
-   Top states and cities
-   Fulfilment comparison
-   B2B vs B2C revenue split
-   Product style performance
-   Running totals & ranking

------------------------------------------------------------------------

## 📦 BI Integration Layer (Planned)

Five reporting-ready SQL views were created to support dashboard
development:

-   vw_MonthlyRevenue
-   vw_CategoryPerformance
-   vw_StateRevenue
-   vw_FulfilmentSummary
-   vw_OrderStatus

A Power BI dashboard layer will be added in the next iteration.

------------------------------------------------------------------------

## 🛠️ How to Run

1.  Create database: CREATE DATABASE AmazonSales_Project;
2.  Import raw CSV as Amazon_Raw_Data
3.  Run amazon_sales_analysis.sql
4.  Query the views for reporting

------------------------------------------------------------------------

## ⚙️ Tech Stack

-   SQL Server 2019+
-   SSMS
-   Power BI (Planned)
-   GitHub

------------------------------------------------------------------------

## 💡 Skills Demonstrated

-   Database normalization (1NF → 3NF)
-   Data quality auditing
-   Multi-table JOIN logic
-   Window functions (SUM OVER, RANK, LAG)
-   CTEs
-   KPI derivation
-   BI-ready view creation

------------------------------------------------------------------------

## 🚀 Future Improvements

-   Add indexing strategy
-   Optimize date aggregations
-   Deploy to cloud SQL
-   Add Power BI dashboard

------------------------------------------------------------------------

## 👤 Author

Javariya Sohail\
Computer Science Student \| Aspiring Data Analyst
