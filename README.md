# Meteorite: E-commerce Customer & Sales Analytics

_Status: complete_

## 1. Business Problem

Online retailers generate huge volumes of transaction data but often can't answer basic questions about where their revenue actually comes from: which time periods, customers, and products matter most, and whether the business depends on repeat buyers or one-time shoppers. This project analyzes 12 months of transaction data from a UK-based online gift retailer to answer those questions.

## 2. Dataset

UCI Machine Learning Repository's "Online Retail" dataset: 541,909 transaction line items from a UK-based online gift and homeware retailer, covering December 2010 through December 2011. Each row is one product line within an invoice, with columns for InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, and Country. See `data/README.md` for source details and setup instructions. All revenue figures are in pounds sterling (£), the currency of the source data.

## 3. Tools Used
- SQL (SQLite)
- Python (pandas, NumPy, matplotlib) via Jupyter

## 4. Key Questions
1. What drives revenue?
2. Who are the valuable customers?
3. Which products matter?
4. Is retention/repeat purchase a problem?

## 5. Methodology

Built four SQL queries answering the key questions above, then independently rebuilt the same four analyses in pandas and cross-validated every metric between the two (net revenue, monthly revenue, order counts, average order value, top customers, top products, and repeat-purchase rate).

Several data quality issues were identified and corrected:

- Timestamps with an unpadded single-digit hour were silently failing to parse in SQL (about 8% of rows). Fixed by correcting the missing zero rather than dropping the data.
- Cancellation invoices were inflating order counts. Fixed by excluding them from order counts while still netting their value into revenue (net sales, not gross).
- Empty-string CustomerID values (guest checkouts) were excluded from customer-level analysis, since they can't be tied to a specific person.

Cross-validation between SQL and pandas also uncovered two additional issues:

- A customer-count discrepancy. SQL counted 4,372 valid customers, while pandas initially counted 4,339. The gap traced back to 33 customers whose only transactions were cancellations, which pandas had dropped from the customer population.
- A product-ranking bug in the SQL query itself. Grouping by both StockCode and Description split a product's revenue across multiple rows whenever its description had text variants, causing two products (22502 and 22197) to be incorrectly excluded from the top 10.

Details are in `project_log_v3.md` and in the SQL files' own comments.

Phase 2: RFM segmentation (pandas, `MeteoriteP-RFM.ipynb`)

Scored each customer on Recency (days since last purchase), Frequency (number of orders) and Monetary (net revenue), then grouped them into segments which are Champions, Loyal, At Risk, New / Promising, Lost and Others.

- Covers 4,339 customers. The 33 customers whose only transactions were cancellations are left out, since recency only makes sense after a completed purchase.
- Monetary is net revenue (returns subtracted), the same definition as the rest of the project.
- Recency and Monetary are scored 1–5 by quintiles. Frequency uses fixed ranges (1, 2, 3–4, 5–9, 10+ orders), because a third of customers have exactly one order and can't be split into equal groups.
- Segments are based on R and F. Monetary is used afterwards to measure what each segment is worth.
- RFM was built in pandas only. Frequency and Monetary use the same logic already cross-validated in SQL (files 02 and 04), and Recency was spot-checked against known customers.

## 6. Key Findings

- Total net revenue across the period was £9,747,747.93 across roughly 22,000 orders.
- Revenue peaked in November 2011 (~£1.46M), consistent with pre-holiday demand.
- The top 10 products by revenue are almost entirely home decorations and gift items rather than everyday staples. Together with the November peak, this suggests demand is largely gift-driven and may be seasonal, though one year of data cannot confirm a recurring pattern.
- 65.07% of customers with a valid ID (2,845 of 4,372) made more than one purchase. This repeat-buyer group drives roughly £7.6M of revenue, compared to about £0.5M from one-time buyers.
- RFM: Champions are 19% of customers but 64% of revenue. Champions and Loyal together are 23% of customers and 71% of revenue.
- RFM: 383 At Risk customers (frequent buyers who have gone quiet) generated about £565,000 in net revenue over the period, averaging about £1,475 each, with no purchase in about 137 days on average. The top 20 of them account for 23% of that historical revenue.
- RFM: Lost customers are the largest group (31% of customers) but bring in only 7% of revenue.

## 7. Business Recommendations

Make retention the first priority to test.

Repeat customers generate the vast majority of revenue, making retention a priority worth investigating. Loyalty programs and targeted campaigns could be tested against acquisition efforts to determine which produces the better return.

Protect the Champions, since a fifth of customers carry nearly two thirds of revenue. Start retention work with the top 20 At Risk customers, who account for the most historical revenue in that group, through personal outreach, and use a cheaper targeted campaign for the remaining 363. Whether outreach actually wins them back is something the campaign itself would need to measure. Avoid heavy spending on Lost customers.

Align inventory and marketing pushes for décor and gift categories ahead of the November peak. Timing At Risk outreach before the autumn peak, alongside new seasonal collections, would also test whether these customers return when demand is highest.

In the longer term, improving guest-checkout attribution (encouraging account creation or capturing customer identity at checkout) would let a larger share of revenue be tied to identifiable, retainable customers.

## 8. Limitations

- One year of data from a single UK retailer covers only one holiday cycle, so seasonal patterns can't be confirmed as recurring, and recency can't fully separate lapsed customers from annual buyers.
- The findings are descriptive. They show where revenue has come from, not which interventions would increase it.
- Non-product administrative codes beyond the top 10 products were not fully audited.
- `03_product_analysis.sql` uses `MAX(Description)` to pick one label for products with several description variants, which occasionally shows an internal note instead of the real product name. Revenue and quantity figures are unaffected.
- In the RFM phase, segment rules were chosen by hand rather than learned from data, "Others" (a quarter of customers) has no specific label, and the RFM work was not rebuilt in SQL.

## 9. Repo Structure
```
meteorite/
  README.md
  project_log_v3.md
  notebooks/
    MeteoritePandas.ipynb
    MeteoriteP-RFM.ipynb
  sql/
    01_revenue_analysis.sql
    02_customer_analysis.sql
    03_product_analysis.sql
    04_repeat_purchase_analysis.sql
  charts/
    Charts.pdf
    rfm_share_by_segment.png
    rfm_top20_at_risk.png
  data/
    README.md
    Online Retail.csv
```
