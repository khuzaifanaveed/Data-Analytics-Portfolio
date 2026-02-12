# =================================================
# Revenue & Growth
# =================================================
# 
# Total Revenue
SELECT  ROUND(SUM(TotalItemValue),2) AS TotalRevenue
FROM factsales;

# Total Order
SELECT COUNT(DISTINCT order_id) AS TotalOrders
FROM factsales;

# Monthly trend
SELECT
    d.Year,
    d.Month,
    SUM(f.TotalItemValue) AS MonthlyRevenue
FROM factsales f
JOIN dimdate d
    ON f.order_date= d.FullDate
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;

# =================================================
# Product Performance
# =================================================
#
# Top 10 products
SELECT
    dp.product_category_name,
    SUM(f.TotalItemValue) AS Revenue
FROM factsales f
JOIN dimproduct dp
    ON f.product_id = dp.product_id
GROUP BY dp.product_category_name
ORDER BY Revenue DESC
LIMIT 10;

# Average basket size
SELECT
    ROUND(AVG(ItemCount),2) AS AvgItemsPerOrder
FROM (
    SELECT order_id, COUNT(*) AS ItemCount
    FROM factsales
    GROUP BY order_id
);

# =================================================
# Customer Analysis
# =================================================
#
# Repeat Customers
SELECT
    CustomerSegment,
    COUNT(*) AS Customers
FROM dimcustomer
GROUP BY CustomerSegment;

# =================================================
# Seller Performance
# =================================================
#
SELECT
    ds.SellerKey,
    SUM(f.TotalItemValue) AS Revenue
FROM factsales f
JOIN dimseller ds
    ON f.seller_id = ds.seller_id
GROUP BY ds.SellerKey
ORDER BY Revenue DESC;

# =================================================
# Delivery Performance
# =================================================
#
# Average delay
SELECT
    ROUND(AVG(DeliveryDelay),2) AS AvgDelayDays
FROM factsales;

# Late deliveries
SELECT
    ROUND(
        SUM(CASE WHEN DeliveryDelay > 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS LateDeliveryPct
FROM factsales;

# =================================================
# Reviews
# =================================================
#
# Average review score
SELECT
    ROUND(AVG(review_score),2) AS AvgReviewScore
FROM factreviews;

# Review vs delivery delay
SELECT
    CASE 
        WHEN DeliveryDelay > 0 THEN 'Late'
        ELSE 'On Time'
    END AS DeliveryStatus,
    ROUND(AVG(review_score),2) AS AvgRating
FROM factreviews
GROUP BY DeliveryStatus;

# Rating by customer segment
SELECT
    dc.CustomerSegment,
    ROUND(AVG(fr.review_score),2) AS AvgRating
FROM factreviews fr
JOIN dimcustomer dc
    ON fr.customer_unique_id = dc.customer_unique_id
GROUP BY dc.CustomerSegment;

# =================================================
# Geography
# =================================================
#
# Revenue by State
SELECT
    dc.customer_state,
    SUM(f.TotalItemValue) AS Revenue
FROM factsales f
JOIN dimcustomer dc
    ON f.customer_unique_id = dc.customer_unique_id
GROUP BY dc.customer_state
ORDER BY Revenue DESC;

# Average rating by state
SELECT
    dc.customer_state,
    ROUND(AVG(fr.review_score),2) AS AvgRating
FROM factreviews fr
JOIN dimcustomer dc
    ON fr.customer_unique_id = dc.customer_unique_id
GROUP BY dc.customer_state
ORDER BY AvgRating DESC;

