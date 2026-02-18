# 🛒 Brazil E-Commerce Sales & Customer Analytics (2016–2018)

## 📊 Project Overview

This project analyzes transactional e-commerce data from a large Brazilian marketplace (provided by Olist) covering 2016–2018.

The goal is to move beyond simple revenue reporting and answer:

* What drives revenue across products and order sizes?
* How does the customer base grow and churn over time?
* Are delays impacting customer satisfaction?
* How do payment behavior and installments influence order value?
* Is revenue concentrated in specific segments or distributed broadly?

The project focuses on:

* Relational modeling in SQL (MySQL)
* Star schema design
* Advanced DAX (churn, cumulative customers, growth rates)
* Analytical storytelling in Power BI

---

## 📥 Data Source

Data is sourced from the publicly available **Olist Brazilian E-Commerce Dataset** on Kaggle:

🔗 [https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The dataset contains:

* Orders
* Order items
* Customers
* Products
* Sellers
* Payments
* Reviews
* Geolocation data

The data represents real commercial transactions between 2016 and 2018.

---

## 📷 Dashboard Preview

This dashboard analyzes revenue performance, product dynamics, customer lifecycle, and payment behavior across the Brazilian e-commerce marketplace (2016–2018).

Below is a preview of the interactive Power BI report.

### 📌 Executive Overview

![Overview](images/page1.jpg)

### 📦 Product Performance & Order Dynamics

![Products](images/page2.jpg)

### 👥 Customer Lifecycle

![Lifecycle](images/page3.jpg)

### 💳 Payments & Customer Experience

![Payments](images/page4.jpg)

---

## 🗂️ Project Structure

Perfect — thanks for clarifying 👍
Let’s correct the **Project Structure** section to accurately reflect your actual folder setup.

Here is the corrected Markdown section (you can replace the previous one in your README):

---

## 🗂️ Project Structure

### 📁 01 - Raw Data

Contains the original CSV files downloaded from the Olist Kaggle dataset.

These files are:

* Unmodified
* Stored in original format
* Used as source data for SQL ingestion

This folder ensures reproducibility and transparency of the data pipeline.

---

### 🛠️ 02 - SQL

Contains all SQL scripts used to build the analytical data model.

#### 01 - Staging Tables.sql

* Creation of raw staging tables
* Definition of data types
* CSV ingestion using `LOAD DATA INFILE`

#### 02 - Cleaning & Modeling.sql

* Filtering to delivered orders
* Data validation checks
* Creation of dimension tables:
* 
  * `DimCustomer`
  * `DimProduct`
  * `DimSeller`
  * `DimOrder`
  * `DimGeolocation`
  * `DimDate`
* Creation of fact tables:

  * `FactSales`
  * `FactReviews`
  * `FactPayments`

* Product category simplification
* Referential integrity checks between facts and dimensions

#### 03 - Exploratory Analysis.sql

Exploratory queries validating data quality and business metrics before modeling:

**Revenue & Growth**
* Total revenue calculation
* Order count validation
* Monthly revenue trend analysis

**Product Performance**
* Top 10 product categories by revenue
* Average basket size (items per order)

**Customer Analysis**
* Customer segmentation distribution
* Repeat customer identification

**Seller Performance**
* Revenue contribution by seller
* Top performers ranking

**Delivery Performance**
* Average delivery delay metrics
* Late delivery percentage calculation

**Reviews & Satisfaction**
* Average review score across orders
* Review correlation with delivery performance
* Rating distribution by customer segment

**Geography**
* Revenue and rating analysis by state
* Regional performance benchmarking

This step ensured data integrity, validated join logic, and informed modeling decisions before Power BI visualization.


---

### 📊 03 - PowerBI

Contains:

* The `.pbix` file with the final dashboard
* Full star schema implementation
* Advanced DAX measures for:

  * Revenue growth
  * Customer lifecycle
  * Churn (120-day inactivity rule)
  * Net customer growth
  * Order value distribution
  * Installment analysis

The Power BI model includes:

* Proper relationship management
* Date dimension modeling
* Context-aware cumulative calculations
* Cross-grain filtering logic

---

If you'd like, I can now:

* Slightly tighten the README tone to sound more “senior-level”
* Or create a short version specifically optimized for recruiters
* Or generate a clean GitHub-ready final version with badges and formatting polish 🚀

---

## 📑 Dashboard Pages

### 📌 Executive Overview

High-level business performance indicators:

* Total Revenue
* Total Orders
* Average Delivery Delay
* Average Rating
* Monthly Revenue Trend
* Revenue by State (map)

Provides a top-level snapshot of marketplace health.

---

### 📦 Product Performance & Order Dynamics

Focuses on product and basket structure:

* Revenue Contribution by Product Category
* Top 10 Products by Revenue
* Revenue by Weight Category
* Number of Orders by Order Value Bin
* Revenue by Order Value Bin

This page highlights:

* Revenue concentration
* Basket size distribution
* Whether expensive orders drive performance

---

### 👥 Customer Lifecycle

Advanced customer analytics:

* Total Customers (cumulative)
* New Customers per month
* Churned Customers (120-day inactivity rule)
* Net Customer Growth
* Churn Rate
* Churn by State
* Churn by Product Category

Key modeling concepts:

* Churn defined dynamically based on last purchase date
* Context-aware cumulative customer calculations

This page highlights acquisition, retention, and sustainability of growth.

---

### 💳 Payments & Customer Experience

Analyzes financing behavior and customer satisfaction:

* Revenue Contribution by Payment Type
* Orders Contribution by Payment Type
* Revenue per Order by Payment Type
* Revenue by Installment Bin
* Installments vs Satisfaction
* Average Rating by Payment Type

This page explores:

* Payment dominance
* Installment impact on revenue
* Relationship between financing behavior and customer experience

---

## 🧠 Key Analytical Concepts

* **Churn Definition** = No purchase within 120 days of selected date
* **Total Customers To Date** = Cumulative distinct customers up to selected date
* **Net Customer Growth** = New − Churned
* **Revenue Growth %** = Month-over-month change
* **Order Value Bucketing** for basket analysis
* **Star schema modeling** for proper filter propagation

---

## 🛠️ Tools Used

* MySQL
* Microsoft Excel (data inspection)
* Power BI
* DAX (advanced time intelligence & churn logic)

---

## 📝 Notes

* Dataset sourced from Kaggle (Olist).
* Project focuses on dimensional modeling and lifecycle analytics.
* Churn logic built dynamically using DAX and context handling.
* Designed as a portfolio project demonstrating SQL + BI modeling proficiency.

---

## 🚀 Future Extensions

Potential future improvements:

* Profitability modeling (if cost data available)
* Predictive churn modeling
* Full ETL pipeline automation
* Real-time dashboard deployment