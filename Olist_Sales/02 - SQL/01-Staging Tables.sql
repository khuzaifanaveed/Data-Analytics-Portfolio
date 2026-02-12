# =================================================
# Create Database
# =================================================
CREATE DATABASE olist_dw;
USE olist_dw;

# =================================================
# Make Staging tables
# =================================================
# -------------------------------------------------
# Customers
# -------------------------------------------------
CREATE TABLE stg_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE stg_customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @customer_id,
  @customer_unique_id,
  @zip,
  @city,
  @state
)
SET
  customer_id = NULLIF(@customer_id,''),
  customer_unique_id = NULLIF(@customer_unique_id,''),
  customer_zip_code_prefix = NULLIF(@zip,''),
  customer_city = NULLIF(@city,''),
  customer_state = NULLIF(@state,'');

# -------------------------------------------------
# Geolocations
# -------------------------------------------------
CREATE TABLE stg_geolocations (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(8,6),
    geolocation_lng DECIMAL(9,6),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_geolocation_dataset.csv'
INTO TABLE stg_geolocations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @zip,
  @lat,
  @lng,
  @city,
  @state
)
SET
  geolocation_zip_code_prefix = NULLIF(@zip,''),
  geolocation_lat = NULLIF(@lat,''),
  geolocation_lng = NULLIF(@lng,''),
  geolocation_city = NULLIF(@city,''),
  geolocation_state = NULLIF(@state,'');

# -------------------------------------------------
# Order Items
# -------------------------------------------------
CREATE TABLE stg_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE stg_order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @order_id,
  @order_item_id,
  @product_id,
  @seller_id,
  @shipping_limit_date,
  @price,
  @freight_value
)
SET
  order_id = @order_id,
  order_item_id = NULLIF(@order_item_id,''),
  product_id = @product_id,
  seller_id = @seller_id,
  shipping_limit_date = STR_TO_DATE(NULLIF(@shipping_limit_date,''), '%Y-%m-%d %H:%i:%s'),
  price = NULLIF(@price,''),
  freight_value = NULLIF(@freight_value,'');

# -------------------------------------------------
# Payments
# -------------------------------------------------
CREATE TABLE stg_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE stg_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @order_id,
  @payment_sequential,
  @payment_type,
  @payment_installments,
  @payment_value
)
SET
  order_id = @order_id,
  payment_sequential = NULLIF(@payment_sequential,''),
  payment_type = NULLIF(@payment_type,''),
  payment_installments = NULLIF(@payment_installments,''),
  payment_value = NULLIF(@payment_value,'');

# -------------------------------------------------
# Reviews
# -------------------------------------------------
CREATE TABLE stg_reviews (
    review_id VARCHAR(250),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_clean.csv'
INTO TABLE stg_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @review_id,
  @order_id,
  @review_score,
  @review_comment_title,
  @review_comment_message,
  @review_creation_date,
  @review_answer_timestamp
)
SET
  review_id = NULLIF(@review_id,''),
  order_id = NULLIF(@order_id,''),
  review_score = NULLIF(@review_score,''),
  review_comment_title = NULLIF(@review_comment_title,''),
  review_comment_message = NULLIF(@review_comment_message,''),
  review_creation_date = STR_TO_DATE(NULLIF(@review_creation_date,''), '%Y-%m-%d %H:%i:%s'),
  review_answer_timestamp = STR_TO_DATE(NULLIF(@review_answer_timestamp,''), '%Y-%m-%d %H:%i:%s');

# -------------------------------------------------
# Orders
# -------------------------------------------------
CREATE TABLE stg_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE stg_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @order_id,
  @customer_id,
  @order_status,
  @purchase,
  @approved,
  @carrier,
  @delivered,
  @estimated
)
SET
  order_id = @order_id,
  customer_id = @customer_id,
  order_status = @order_status,
  order_purchase_timestamp = STR_TO_DATE(@purchase, '%Y-%m-%d %H:%i:%s'),
  order_approved_at = STR_TO_DATE(NULLIF(@approved,''), '%Y-%m-%d %H:%i:%s'),
  order_delivered_carrier_date = STR_TO_DATE(NULLIF(@carrier,''), '%Y-%m-%d %H:%i:%s'),
  order_delivered_customer_date = STR_TO_DATE(NULLIF(@delivered,''), '%Y-%m-%d %H:%i:%s'),
  order_estimated_delivery_date = STR_TO_DATE(@estimated, '%Y-%m-%d %H:%i:%s');

# -------------------------------------------------
# Products
# -------------------------------------------------
CREATE TABLE stg_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE stg_products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @product_id,
  @category,
  @name_len,
  @desc_len,
  @photos,
  @weight,
  @length,
  @height,
  @width
)
SET
  product_id = @product_id,
  product_category_name = NULLIF(@category,''),
  product_name_lenght = NULLIF(@name_len,''),
  product_description_lenght = NULLIF(@desc_len,''),
  product_photos_qty = NULLIF(@photos,''),
  product_weight_g = NULLIF(@weight,''),
  product_length_cm = NULLIF(@length,''),
  product_height_cm = NULLIF(@height,''),
  product_width_cm = NULLIF(@width,'');

# -------------------------------------------------
# Sellers
# -------------------------------------------------
CREATE TABLE stg_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE stg_sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @seller_id,
  @zip,
  @city,
  @state
)
SET
  seller_id = @seller_id,
  seller_zip_code_prefix = NULLIF(@zip,''),
  seller_city = NULLIF(@city,''),
  seller_state = NULLIF(@state,'');

# -------------------------------------------------
# Category Translations
# -------------------------------------------------
CREATE TABLE stg_cat_name_translations(
	product_category_name VARCHAR(50),
	product_category_name_english VARCHAR(50)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE stg_cat_name_translations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @cat_pt,
  @cat_en
)
SET
  product_category_name = NULLIF(@cat_pt,''),
  product_category_name_english = NULLIF(@cat_en,'');

