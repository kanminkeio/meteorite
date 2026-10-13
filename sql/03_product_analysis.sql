-- Top 10 products by revenue and quantity sold.
-- Excluded postage/shipping line items. They aren't real products.
-- Early version grouped by StockCode and Description together, which split some
-- products' revenue across multiple rows and excluded two real top-10 products out of the ranking. Fixed by grouping on StockCode only.
-- MAX(Description) just picks a label for each group. It sometimes grabs an internal note instead of the real product name, text only.

Select Sum(Quantity*UnitPrice) as revenue, SUM(Quantity) as total_quantity_sold, StockCode, MAX(Description)
From retail
where description not like '%postage%'
group by StockCode
order by revenue desc limit 10
