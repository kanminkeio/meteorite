-- What percent of customers are repeat buyers vs. one-time.
-- A CTE builds order count and a repeat/one-time label per customer (same logic as 02_customer_analysis.sql, but for everyone, not just the top 10). 
-- The outer query counts each group and turns it into a percentage.
-- Result: 65.07% repeat rate.

WITH cte_name AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS revenue,
        COUNT(DISTINCT CASE WHEN InvoiceNo NOT LIKE 'C%' THEN InvoiceNo END) AS distinct_orders,
        CASE WHEN COUNT(DISTINCT CASE WHEN InvoiceNo NOT LIKE 'C%' THEN InvoiceNo END) > 1
            THEN 'repeat'
            ELSE 'one-time'
        END AS customer_type
    FROM retail
    WHERE CustomerID IS NOT NULL AND CustomerID != ''
    GROUP BY CustomerID
)
SELECT
    COUNT(CASE WHEN customer_type = 'repeat' THEN 1 END) AS repeat_customers,
    COUNT(CASE WHEN customer_type = 'one-time' THEN 1 END) AS one_time_customers,
    COUNT(CASE WHEN customer_type = 'repeat' THEN 1 END) * 100.0
        / (COUNT(CASE WHEN customer_type = 'one-time' THEN 1 END) + COUNT(CASE WHEN customer_type = 'repeat' THEN 1 END))
        AS repeat_customer_rate_pct
FROM cte_name;
