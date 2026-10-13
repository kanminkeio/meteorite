-- Top customers by revenue, plus repeat vs. one-time classification.
-- Dropped rows with no CustomerID (guest checkouts), since they can't be tied to a person.
-- Order count skips cancellations, same reasoning as the revenue file. Revenue itself stays net, only the order count excludes cancellations.

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
ORDER BY revenue DESC
LIMIT 10;
