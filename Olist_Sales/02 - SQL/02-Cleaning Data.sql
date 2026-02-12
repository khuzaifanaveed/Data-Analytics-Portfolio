# =================================================
# Checking the row count
# =================================================
SELECT 'customers' AS table_name, COUNT(*) FROM stg_customers
UNION ALL
SELECT 'geolocations', COUNT(*) FROM stg_geolocations
UNION ALL
SELECT 'order_items', COUNT(*) FROM stg_order_items
UNION ALL
SELECT 'orders', COUNT(*) FROM stg_orders
UNION ALL
SELECT 'payments', COUNT(*) FROM stg_payments
UNION ALL
SELECT 'products', COUNT(*) FROM stg_products
UNION ALL
SELECT 'reviews', COUNT(*) FROM stg_reviews
UNION ALL
SELECT 'sellers', COUNT(*) FROM stg_sellers;

# =================================================
# General Checks
# =================================================
# -------------------------------------------------
# Are there any orders without customers?
# -------------------------------------------------
SELECT COUNT(*)
FROM stg_orders o
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

# -------------------------------------------------
# Redundant items in the items table?
# -------------------------------------------------
SELECT COUNT(*)
FROM stg_order_items oi
LEFT JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

# -------------------------------------------------
# Orders without payments?
# -------------------------------------------------
SELECT COUNT(*)
FROM stg_orders o
LEFT JOIN stg_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

# -------------------------------------------------
# Different order status/nulls in delivery date
# -------------------------------------------------
SELECT DISTINCT(order_status)
FROM stg_orders;

SELECT order_status, COUNT(*)
FROM stg_orders
GROUP BY order_status;

SELECT COUNT(*) 
FROM stg_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

# =================================================
# Creating Dimensions and Facts Tables
# =================================================
# Only keeping the delivered orders
DROP TABLE IF EXISTS clean_orders;
CREATE TABLE clean_orders AS
SELECT *
FROM stg_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

# -------------------------------------------------
# Customers Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimCustomer;
CREATE TABLE DimCustomer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_unique_id) AS CustomerKey,
    c.customer_unique_id,
    MIN(c.customer_city) AS customer_city,
    MIN(c.customer_state) AS customer_state,
    MIN(c.customer_zip_code_prefix) AS ZipPrefix,
    MIN(o.order_purchase_timestamp) AS FirstPurchaseDate,
    COUNT(DISTINCT o.order_id) AS TotalOrders,
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 10 THEN 'Loyal'
        WHEN COUNT(DISTINCT o.order_id) BETWEEN 3 AND 9 THEN 'Regular'
        ELSE 'Occasional'
    END AS CustomerSegment
FROM stg_customers c
JOIN stg_orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;

# -------------------------------------------------
# Products Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimProduct;
CREATE TABLE DimProduct AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS ProductKey,
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name,
    p.product_weight_g,
    CASE
        WHEN p.product_weight_g < 500 THEN 'Light'
        WHEN p.product_weight_g BETWEEN 500 AND 2000 THEN 'Medium'
        ELSE 'Heavy'
    END AS WeightCategory
FROM stg_products p
LEFT JOIN stg_cat_name_translations t
    ON p.product_category_name = t.product_category_name;

# -------------------------------------------------
# Seller Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimSeller;
CREATE TABLE DimSeller AS
SELECT
    ROW_NUMBER() OVER (ORDER BY seller_id) AS SellerKey,
    seller_id,
    seller_city,
    seller_state
FROM stg_sellers;

# -------------------------------------------------
# Geolocation Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimGeolocation;
CREATE TABLE DimGeolocation AS
SELECT
    geolocation_zip_code_prefix AS ZipPrefix,
    AVG(geolocation_lat) AS AvgLatitude,
    AVG(geolocation_lng) AS AvgLongitude,
    MAX(geolocation_city) AS City,
    MAX(geolocation_state) AS State
FROM stg_geolocations
GROUP BY geolocation_zip_code_prefix;

# -------------------------------------------------
# Date Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimDate;
CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName VARCHAR(20),
    Day INT,
    DayOfWeek INT,
    DayName VARCHAR(20),
    IsWeekend BOOLEAN
);

SET @min_date = (SELECT MIN(DATE(order_purchase_timestamp)) FROM stg_orders);
SET @max_date = (SELECT MAX(DATE(order_purchase_timestamp)) FROM stg_orders);
SET @@cte_max_recursion_depth = 5000;

INSERT INTO DimDate
WITH RECURSIVE date_series AS (
    SELECT @min_date AS dt
    UNION ALL
    SELECT dt + INTERVAL 1 DAY
    FROM date_series
    WHERE dt < @max_date
)
SELECT
    DATE_FORMAT(dt, '%Y%m%d') + 0 AS DateKey,
    dt,
    YEAR(dt),
    QUARTER(dt),
    MONTH(dt),
    MONTHNAME(dt),
    DAY(dt),
    WEEKDAY(dt),
    DAYNAME(dt),
    CASE WHEN WEEKDAY(dt) IN (5,6) THEN TRUE ELSE FALSE END
FROM date_series;

# -------------------------------------------------
# Sales Fact Table
# -------------------------------------------------
DROP TABLE IF EXISTS FactSales;
CREATE TABLE FactSales AS
SELECT
    o.order_id,
    c.customer_unique_id,
    oi.product_id,
    oi.seller_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS TotalItemValue,
    DATEDIFF(o.order_delivered_customer_date,
             o.order_estimated_delivery_date) AS DeliveryDelay
FROM clean_orders o
JOIN stg_order_items oi
    ON o.order_id = oi.order_id
JOIN stg_customers c
	ON o.customer_id = c.customer_id;

# -------------------------------------------------
# Reviews Fact Table
# -------------------------------------------------
DROP TABLE IF EXISTS FactReviews;
CREATE TABLE FactReviews AS
SELECT
    r.order_id,
    c.customer_unique_id,
    DATE(r.review_creation_date) AS review_date,
    r.review_score,
    DATEDIFF(o.order_delivered_customer_date,
             o.order_estimated_delivery_date) AS DeliveryDelay
FROM stg_reviews r
JOIN clean_orders o
    ON r.order_id = o.order_id
JOIN stg_customers c
	ON o.customer_id = c.customer_id;
