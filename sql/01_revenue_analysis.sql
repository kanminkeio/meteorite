-- Monthly revenue, order count, and average order value.
-- Some timestamps had a missing leading zero on the hour (like "8:26" instead of "08:26"), which broke date parsing. Fixed by padding the hour before parsing.
-- Revenue is net (returns included). Order count skips cancellations, since cancellation reverses an order rather than being a new one.

SELECT
    SUM(Quantity * UnitPrice) AS revenue,
    COUNT(DISTINCT CASE WHEN InvoiceNo NOT LIKE 'C%' THEN InvoiceNo END) AS order_count,
    SUM(Quantity * UnitPrice) / COUNT(DISTINCT CASE WHEN InvoiceNo NOT LIKE 'C%' THEN InvoiceNo END) AS avg_order_value,
    STRFTIME('%Y-%m',
        CASE WHEN SUBSTR(InvoiceDate, 13, 1) = ':'
        THEN SUBSTR(InvoiceDate, 1, 11) || '0' || SUBSTR(InvoiceDate, 12)
        ELSE InvoiceDate END
    ) AS month
FROM retail
WHERE InvoiceDate IS NOT NULL
GROUP BY month
ORDER BY month ASC;
