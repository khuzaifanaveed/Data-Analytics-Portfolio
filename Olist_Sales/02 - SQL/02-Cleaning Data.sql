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

# -------------------------------------------------
# Checking city names:
# We will only use city names from geolocation
# -------------------------------------------------
SELECT DISTINCT(geolocation_zip_code_prefix), COUNT(DISTINCT(geolocation_city)) as variations, MAX(geolocation_city)
FROM stg_geolocations
GROUP BY geolocation_zip_code_prefix
ORDER BY variations DESC;

SELECT DISTINCT(customer_city), geolocation_city, customer_zip_code_prefix, customer_state, geolocation_state
FROM stg_customers
JOIN stg_geolocations
	ON customer_zip_code_prefix = geolocation_zip_code_prefix
WHERE customer_city != geolocation_city;

SELECT geolocation_city, seller_city, seller_zip_code_prefix, seller_state, geolocation_state
FROM stg_sellers
JOIN stg_geolocations
	ON seller_zip_code_prefix = geolocation_zip_code_prefix
WHERE seller_city != geolocation_city;

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
    DISTINCT(c.customer_unique_id) AS CustomerUniqueID,
    ROW_NUMBER() OVER (ORDER BY c.customer_unique_id) AS CustomerKey,
    MIN(c.customer_zip_code_prefix) AS ZipPrefix,
    DATE(MIN(o.order_purchase_timestamp)) AS FirstPurchaseDate,
    CASE
        WHEN COUNT(DISTINCT o.order_id) >= 10 THEN 'Loyal'
        WHEN COUNT(DISTINCT o.order_id) BETWEEN 3 AND 9 THEN 'Regular'
        ELSE 'Occasional'
    END AS CustomerSegment
FROM stg_customers c
INNER JOIN stg_orders o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;

# Surrogate keys not used as primary keys due to memory errors
ALTER TABLE DimCustomer
ADD PRIMARY KEY (CustomerUniqueID);

# -------------------------------------------------
# Seller Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimSeller;
CREATE TABLE DimSeller AS
SELECT
	DISTINCT(seller_id) AS SellerID,
    ROW_NUMBER() OVER (ORDER BY seller_id) AS SellerKey,
    MIN(seller_zip_code_prefix) AS ZipPrefix
FROM stg_sellers
GROUP BY seller_id;

# Surrogate keys not used as primary keys due to memory errors
ALTER TABLE DimSeller
ADD PRIMARY KEY (SellerID);

# -------------------------------------------------
# Products Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimProduct;
CREATE TABLE DimProduct AS
SELECT
	DISTINCT(p.product_id) AS ProductID,
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS ProductKey, REPLACE(COALESCE(t.product_category_name_english, p.product_category_name, "Miscellaneous"), "_", " ") AS ProductCategoryName,
    p.product_weight_g AS ProductWeight,
    CASE
        WHEN p.product_weight_g < 500 THEN 'Light'
        WHEN p.product_weight_g BETWEEN 500 AND 2000 THEN 'Medium'
        ELSE 'Heavy'
    END AS WeightCategory
FROM stg_products p
LEFT JOIN stg_cat_name_translations t
    ON p.product_category_name = t.product_category_name;

# Surrogate keys not used as primary keys due to memory errors
ALTER TABLE DimProduct
ADD PRIMARY KEY (ProductID);

# -------------------------------------------------
# Geolocation Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimGeolocation;
CREATE TABLE DimGeolocation AS
SELECT
    DISTINCT(geolocation_zip_code_prefix) AS ZipPrefix,
    AVG(geolocation_lat) AS AvgLatitude,
    AVG(geolocation_lng) AS AvgLongitude,
    MAX(geolocation_city) AS City,
    MAX(geolocation_state) AS State
FROM stg_geolocations
GROUP BY geolocation_zip_code_prefix;

# Surrogate keys not used as primary keys due to memory errors
ALTER TABLE DimGeolocation
ADD PRIMARY KEY (ZipPrefix);

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
# Order Dimension Table
# -------------------------------------------------
DROP TABLE IF EXISTS DimOrder;
CREATE TABLE DimOrder AS
SELECT
    o.order_id AS OrderID,
    c.customer_unique_id AS CustomerUniqueID,
    DATE(o.order_purchase_timestamp) AS OrderDate,
    DATE(o.order_delivered_customer_date) AS OrderDeliveryDate,
    DATE(o.order_estimated_delivery_date) AS OrderEstimatedDeliveryDate,
    DATEDIFF(o.order_delivered_customer_date,
             DATE(o.order_purchase_timestamp)) AS DeliveryDelay,
    DATEDIFF(o.order_delivered_customer_date,
             o.order_estimated_delivery_date) AS DeliveryEstimateDelay
FROM clean_orders o
JOIN stg_customers c
    ON o.customer_id = c.customer_id;

ALTER TABLE DimOrder
ADD PRIMARY KEY (OrderID);

# -------------------------------------------------
# Sales Fact Table
# -------------------------------------------------
DROP TABLE IF EXISTS FactSales;
CREATE TABLE FactSales AS
SELECT
    oi.order_id AS OrderID,
    oi.product_id AS ProductID,
    oi.seller_id AS SellerID,
    oi.order_item_id AS OrderItemID,
    oi.price AS ItemPrice,
    oi.freight_value AS ItemFreightValue,
    (oi.price + oi.freight_value) AS TotalItemValue
FROM clean_orders o
JOIN stg_order_items oi
    ON o.order_id = oi.order_id;

ALTER TABLE FactSales
ADD PRIMARY KEY (OrderID, OrderItemID);

# -------------------------------------------------
# Reviews Fact Table
# -------------------------------------------------
DROP TABLE IF EXISTS FactReviews;
CREATE TABLE FactReviews AS
SELECT
    r.order_id AS OrderID,
    DATE(r.review_creation_date) AS ReviewDate,
    r.review_score AS ReviewScore
FROM stg_reviews r
JOIN clean_orders o
    ON r.order_id = o.order_id
JOIN stg_customers c
	ON o.customer_id = c.customer_id;

# -------------------------------------------------
# Payments Fact Table
# -------------------------------------------------
DROP TABLE IF EXISTS FactPayments;
CREATE TABLE FactPayments AS
SELECT
    p.order_id AS OrderID,
    REPLACE(p.payment_type, "_", " ") AS PaymentType,
    p.payment_installments AS PaymentInstallments,
    p.payment_value AS PaymentValue
FROM stg_payments p
JOIN clean_orders o
    ON p.order_id = o.order_id
JOIN stg_customers c
    ON o.customer_id = c.customer_id;


# =================================================
# Final Checks on dimension tables
# =================================================
# -------------------------------------------------
# Fact Sales vs dimensions
# -------------------------------------------------
SELECT DISTINCT SellerID
FROM factsales f
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimseller d 
    WHERE f.SellerID = d.SellerID
);

SELECT DISTINCT ProductID
FROM factsales f
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimproduct d 
    WHERE f.ProductID = d.ProductID
);

SELECT DISTINCT OrderID
FROM factsales f
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimorder d 
    WHERE f.OrderID = d.OrderID
);

# -------------------------------------------------
# Fact Reviews vs dimensions
# -------------------------------------------------
SELECT DISTINCT OrderID
FROM factreviews f
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimorder d 
    WHERE f.OrderID = d.OrderID
);

# -------------------------------------------------
# Fact Payments vs dimensions
# -------------------------------------------------
SELECT DISTINCT OrderID
FROM factpayments f
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimorder d 
    WHERE f.OrderID = d.OrderID
);

# -------------------------------------------------
# DimSeller vs DimGeolocation
# -------------------------------------------------
SELECT DISTINCT SellerID, ds.ZipPrefix
FROM dimseller ds
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimgeolocation dg 
    WHERE ds.ZipPrefix = dg.ZipPrefix
);

INSERT INTO dimgeolocation (ZipPrefix, AvgLatitude, AvgLongitude, City, State)
SELECT 
    DISTINCT(stgs.seller_zip_code_prefix), 
    state_avg.lat,
    state_avg.lon,
    stgs.seller_city, 
    stgs.seller_state
FROM stg_sellers stgs
JOIN (
    SELECT State, AVG(AvgLatitude) as lat, AVG(AvgLongitude) as lon
    FROM dimgeolocation
    GROUP BY State
) state_avg ON stgs.seller_state = state_avg.State
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimgeolocation dg 
    WHERE stgs.seller_zip_code_prefix = dg.ZipPrefix
)
AND stgs.seller_zip_code_prefix IN (SELECT DISTINCT ZipPrefix FROM dimseller);

# -------------------------------------------------
# DimCustomer vs DimGeolocation
# -------------------------------------------------
SELECT DISTINCT CustomerUniqueID, dc.ZipPrefix
FROM dimcustomer dc
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimgeolocation dg 
    WHERE dc.ZipPrefix = dg.ZipPrefix
);

INSERT INTO dimgeolocation (ZipPrefix, AvgLatitude, AvgLongitude, City, State)
SELECT 
    DISTINCT(stgc.customer_zip_code_prefix), 
    state_avg.lat,
    state_avg.lon,
    stgc.customer_city, 
    stgc.customer_state
FROM stg_customers stgc
JOIN (
    SELECT State, AVG(AvgLatitude) as lat, AVG(AvgLongitude) as lon
    FROM dimgeolocation
    GROUP BY State
) state_avg ON stgc.customer_state = state_avg.State
WHERE NOT EXISTS (
    SELECT 1 
    FROM dimgeolocation dg 
    WHERE stgc.customer_zip_code_prefix = dg.ZipPrefix
)
AND stgc.customer_zip_code_prefix IN (SELECT DISTINCT ZipPrefix FROM dimcustomer);

# -------------------------------------------------
# Simplifying the Product Categories
# -------------------------------------------------
SELECT DISTINCT(ProductCategoryName)
FROM dimproduct;

UPDATE dimproduct p
INNER JOIN (
    SELECT 'construct' AS keyword, 'Construction & Tools' AS macro UNION ALL
    SELECT 'costruction', 'Construction & Tools' UNION ALL
    SELECT 'tool', 'Construction & Tools' UNION ALL
    SELECT 'furniture', 'Home & Living' UNION ALL
    SELECT 'home', 'Home & Living' UNION ALL
    SELECT 'bed', 'Home & Living' UNION ALL
    SELECT 'house', 'Home & Living' UNION ALL
    SELECT 'kitchen', 'Home & Living' UNION ALL
    SELECT 'appliance', 'Home & Living' UNION ALL
    SELECT 'telephony', 'Electronics' UNION ALL
    SELECT 'computer', 'Electronics' UNION ALL
    SELECT 'electronic', 'Electronics' UNION ALL
    SELECT 'tablets', 'Electronics' UNION ALL
    SELECT 'console', 'Electronics' UNION ALL
    SELECT 'game', 'Electronics' UNION ALL
    SELECT 'dvd', 'Electronics' UNION ALL
    SELECT 'audio', 'Electronics' UNION ALL
    SELECT 'fashio', 'Fashion' UNION ALL
    SELECT 'perfume', 'Fashion' UNION ALL
    SELECT 'beauty', 'Fashion' UNION ALL
    SELECT 'sport', 'Sports' UNION ALL
    SELECT 'stationery', 'School & DIY' UNION ALL
    SELECT 'book', 'School & DIY' UNION ALL
    SELECT 'music', 'Toys & Hobby' UNION ALL
    SELECT 'supplies', 'Toys & Hobby' UNION ALL
    SELECT 'stuff', 'Toys & Hobby' UNION ALL
    SELECT 'gift', 'Toys & Hobby' UNION ALL
    SELECT 'toy', 'Toys & Hobby' UNION ALL
    SELECT 'art', 'Toys & Hobby' UNION ALL
    SELECT 'food', 'Food & Drink' UNION ALL
    SELECT 'drink', 'Food & Drink' UNION ALL
    SELECT 'cuisine', 'Food & Drink'
) map ON p.ProductCategoryName LIKE CONCAT('%', map.keyword, '%')
SET p.ProductCategoryName = map.macro;