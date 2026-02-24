# =================================================
# Revenue & Growth
# =================================================
# 
# Total Revenue
SELECT  ROUND(SUM(TotalItemValue),2) AS TotalRevenue
FROM factsales;

# Total Order
SELECT COUNT(DISTINCT OrderID) AS TotalOrders
FROM factsales;

# Monthly trend
SELECT
    d.Year,
    d.Month,
    SUM(f.TotalItemValue) AS MonthlyRevenue
FROM factsales f
JOIN dimorder dor
	on f.OrderID = dor.OrderID
JOIN dimdate d
    ON dor.OrderDate = d.FullDate
GROUP BY d.Year, d.Month
ORDER BY d.Year, d.Month;

# =================================================
# Product Performance
# =================================================
#
# Top 10 product categories
SELECT
    dp.ProductCategoryName,
    SUM(f.TotalItemValue) AS Revenue
FROM factsales f
JOIN dimproduct dp
    ON f.ProductID = dp.ProductID
GROUP BY dp.ProductCategoryName
ORDER BY Revenue DESC
LIMIT 10;

# Average basket size
SELECT
    ROUND(AVG(ItemCount),2) AS AvgItemsPerOrder
FROM (
    SELECT f.OrderID, COUNT(*) AS ItemCount
    FROM factsales f
    JOIN dimorder dor
		ON f.OrderID = dor.OrderID
    GROUP BY OrderID
) item_count_table;

# =================================================
# Customer Analysis
# =================================================
#
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
    ON f.SellerID = ds.SellerID
GROUP BY ds.SellerKey
ORDER BY Revenue DESC;

# =================================================
# Delivery Performance
# =================================================
#
# Average Delivery Time
SELECT
    ROUND(AVG(dor.DeliveryDelay),2) AS AvgDelayDays
FROM factsales fs
JOIN dimorder dor
	ON fs.OrderID = dor.OrderID;

# Deliveries later than expected
SELECT
    ROUND(
        SUM(CASE WHEN dor.DeliveryEstimateDelay > 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS LateDeliveryPct
FROM factsales fs
JOIN dimorder dor
	ON fs.OrderID = dor.OrderID;

# =================================================
# Reviews
# =================================================
#
# Average review score
SELECT
    ROUND(AVG(ReviewScore),2) AS AvgReviewScore
FROM factreviews;

# Review vs delivery delay
SELECT
    CASE 
        WHEN dor.DeliveryEstimateDelay > 0 THEN 'Late'
        ELSE 'On Time'
    END AS DeliveryStatus,
    ROUND(AVG(ReviewScore),2) AS AvgRating
FROM factreviews fr
JOIN dimorder dor
	ON fr.OrderID = dor.OrderID
GROUP BY DeliveryStatus;

# Rating by customer segment
SELECT
    dc.CustomerSegment,
    ROUND(AVG(fr.ReviewScore),2) AS AvgRating
FROM factreviews fr
JOIN dimorder dor
	ON fr.OrderID = dor.OrderID
JOIN dimcustomer dc
    ON dor.CustomerUniqueID = dc.CustomerUniqueID
GROUP BY dc.CustomerSegment;

# =================================================
# Geography
# =================================================
#
# Revenue by State
SELECT
    dg.State,
    SUM(f.TotalItemValue) AS Revenue
FROM factsales f
JOIN dimorder dor
	ON f.OrderID = dor.OrderID
JOIN dimcustomer dc
    ON dor.CustomerUniqueID= dc.CustomerUniqueID
JOIN dimgeolocation dg
	ON dc.ZipPrefix = dg.ZipPrefix
GROUP BY dg.State
ORDER BY Revenue DESC;

# Average rating by state
SELECT
    dg.State,
    ROUND(AVG(fr.ReviewScore),2) AS AvgRating
FROM factreviews fr
JOIN dimorder dor
	ON fr.OrderID = dor.OrderID
JOIN dimcustomer dc
    ON dor.CustomerUniqueID = dc.CustomerUniqueID
JOIN dimgeolocation dg
	ON dc.ZipPrefix = dg.ZipPrefix
GROUP BY dg.State
ORDER BY AvgRating DESC;

