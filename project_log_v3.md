# Project Log

Format: date, task, what I learned, what happened (or what broke, and what was done).
Phase 1 (Aug–Sep) summarised by week
Phase 2 (RFM, Oct) logged per session
---

## 2026-08-07
Task: Build SQL queries for monthly revenue trend (01_revenue_analysis.sql) and top customers / repeat vs one-time classification (02_customer_analysis.sql).

Learned: SELECT/FROM/WHERE/GROUP BY/ORDER BY clause order and syntax; aggregate functions (SUM, COUNT, COUNT DISTINCT); CASE WHEN inside an aggregate for conditional counting; STRFTIME date formatting.

Progress and Error logs
- STRFTIME was returning NULL for ~43,665 rows (~8% of the table), categorizing them into blank months. Sanity-checked by testing NULL InvoiceDate (0 found), then empty-string InvoiceDate (0 found) but neither explained it. Inspected the raw values directly and found single-digit hours missing a leading zero (e.g. "8:26" instead of "08:26"). Fixed with a CASE/SUBSTR expression that pads the hour before parsing. Verified by confirming total revenue and order count matched exactly before and after the fix.
- Cancellation invoices (InvoiceNo starting with 'C') were inflating order counts, since each cancellation has its own invoice number. Fixed by excluding 'C'-prefixed invoices from COUNT(DISTINCT ...), while leaving revenue as net sales (returns subtracted in the revenue total).
- Empty-string CustomerID values (guest checkouts) were slipping through a NULL-only filter, causing one fake "customer" to rank #1 by revenue. Fixed by filtering out both NULL and empty string.
- Decision: revenue = net sales (returns netted in), not gross sales. Order count and Average Order Value (AOV) exclude cancellations, and revenue does not.
- Finding: revenue peaked November 2011 (~£1.46M), perhaps due to pre-holiday demand.

---

## 2026-08-11
Task: Build a query to find the top 10 products by revenue and quantity sold (03_product_analysis.sql).

Learned: GROUP BY with multiple columns needs commas, not "and"; a column used in GROUP BY has to also be in SELECT or you can't tell which row is which; the difference between a LIKE wildcard at the end only ("starts with") vs. wildcards on both sides ("contains anywhere").

Progress and Error logs
- Top 10 by revenue included two shipping/postage line items (StockCodes POST and DOT). These aren't real products and they were distorting the ranking. The first filter attempt only matched descriptions starting with "postage" and missed "DOTCOM POSTAGE". Fixed with wildcards on both sides of "postage."
- Noted at the time as a limitation -> didn't check for other non-product codes beyond the top 10. Fixed later during the pandas cross-validation work.

---

## 2026-08-12
Task: Find what percentage of customers are repeat buyers vs. one-time, using a CTE for the first time (04_repeat_purchase_analysis.sql).

Learned: CTEs (WITH ... AS (...)) build a temporary named result you can query again in an outer SELECT; COUNT('some_text') counts every row regardless of value because it's counting a constant, not checking a condition. In that case, need COUNT(CASE WHEN ... THEN 1 END) instead. In SQL, forcing decimal division (multiplying by 100.0) needs to happen at the exact point the division occurs, not before or after, or integer truncation overrides.

Progress and Error logs
- Integer division truncating before the fix could apply, a stray duplicated multiplication by 100.0 that changed the actual math, then a double-scaling bug from multiplying by 100.0 twice. Learned the correct single-point-of-conversion formula.
- Result: 65.07% repeat customer rate (2,845 repeat vs. 1,527 one-time, out of 4,372 valid customers). Supports a retention-focused recommendation over a pure acquisition strategy.

---

## 2026-08-13 – 2026-08-17 (Python / pandas)
Task: Set up the notebook, load and clean the dataset, and start rebuilding the SQL customer analysis in pandas.

Learned: Jupyter only auto-displays a cell's last line; `.dt` accessor for datetime columns vs. `.str` accessor for text columns are different toolkits for different column types; `pd.to_datetime()` needs an explicit `format=` to parse.

Progress and Error logs
- Built `Revenue` (Quantity × UnitPrice), a month column, and a cancellation-flag column (`Cancel_Ordercount`).
- Tried to drop a column called `Non_Cancel_Ordercount`, but that was a typo, the actual column was named `Cancel_Ordercount`, so the drop errored out. The broken cell sat unresolved in the notebook until it was caught and removed right before final submission.
- Kernel state gets wiped on restart, and I hit this more than once after Windows restarted on its own. Redirecting the repository to D in Anaconda every time this happened was not the most exciting run.

---

## 2026-08-18 – 2026-08-24 (Python / pandas)
Task: Classify customers as repeat vs. one-time in pandas and cross-validate the counts against SQL.

Learned: `.groupby()` + chained aggregation (`.sum()`, `.nunique()`); `np.where()` as pandas' version of SQL's CASE WHEN; boolean negation is `~`, not Python's `not`; `.nlargest(n)` as the pandas equivalent of `ORDER BY ... DESC LIMIT n`; `.reindex()` changes which labels a Series shows (new labels come in as NaN); `.fillna()` replaces those NaN placeholders with a real value.

Progress and Error logs
- Found a discrepancy where SQL counted 4,372 customers, pandas counted 4,339. Cause: pandas' groupby only counted customers who appeared in the cancellation-excluded orders table, silently dropping 33 customers whose only transactions were cancellations. Fixed with `.reindex()` against the full customer list plus `.fillna(0)`, so those 33 are correctly counted as one-time buyers with zero real orders.
- Recomputed repeat/one-time counts and percentage matched SQL's 65.07% exactly.

---

## 2026-08-25 – 2026-08-31 (Python / pandas)
Task: Rebuild the product analysis in pandas, cross-check it against SQL, and start the repeat purchase section.

Learned: multiplying two columns needs each selected separately (`df['A']` times `df['B']`), not combined inside one bracket. A regex character class (`[...]`) matches any single listed character. Real "or" logic is a bare pipe between whole words with no brackets at all (`POST|DOT`, not `[POST|DOT]`). `.str.contains()` needs `na=False` for missing values.

Progress and Error logs
- Cross-validating pandas' top-10-products-by-revenue against `03_product_analysis.sql` revealed a bug: SQL's `GROUP BY StockCode, Description` fragmented a product's true revenue across multiple rows whenever its Description text had variants (typos, case differences, stray internal notes like "damaged" or "wrongly marked carton"). Because no individual entry earned enough to make the top 10 on its own, these items were omitted from the top 10 despite their actual combined sales. Two valid products (22502 and 22197) were mistakenly left out.
- Fixed `03_product_analysis.sql` itself. `GROUP BY` was changed to `StockCode` only, wrapped `Description` in `MAX()` so the query stays valid (SQL needs an aggregate on any selected column not in the GROUP BY). Side effect -> `MAX()` on text compares by character code, and lowercase beats uppercase. Real product names here are conventionally uppercase and the messy internal notes are lowercase, so `MAX(Description)` sometimes shows an internal note instead of the real product name. Revenue and quantity numbers are unaffected; only the label text can look off. 
- Verified: fixed SQL query's top 10 now matches pandas' independently-computed top 10 exactly (same StockCodes, same amounts, same order).

---

## 2026-09-01 (Python / pandas)
Task: Finish the repeat purchase charts and the rest of the notebook's charts.

Learned: `plt.bar()` needs two separate arguments (labels, values), unlike `plt.plot()`. Numeric-looking axis labels (like CustomerID) get plotted as points on a continuous number line unless converted to strings first, producing sparse, misshapen bars instead of evenly spaced ones. A NumPy array (what `np.where()` returns) has no `.groupby()` method; only pandas Series/DataFrames do.

Progress and Error logs
- Bar chart of top 10 customers initially showed only 2-3 thin bars instead of 10. This was caused by plotting against raw numeric CustomerIDs. Fixed with `.astype(str)` on the index.
- Built a revenue-by-customer-type chart (repeat vs. one-time). First attempts used the wrong object (a NumPy array with no `.groupby()`), then the wrong value (order counts instead of revenue), then the wrong population (the top-10 Series instead of full per-customer revenue). Corrected step by step to full per-customer revenue total, grouped by the corrected `customer_type` label.
- Result: repeat customers drive roughly £7.6M in revenue vs. about £0.5M from one-time customers. That supports a retention-focused recommendation.
- Saved the notebook into the project folder on Sept 3.

---

## 2026-10-01 – 2026-10-02 (RFM extension, Python / pandas)
Task: Start phase 2 of Meteorite: RFM (Recency, Frequency, Monetary) customer segmentation. This phase is about turning "retention matters" into specific customers to target.

Learned: date arithmetic with `pd.Timedelta`; `.groupby().agg()` with named outputs builds several per-customer columns in one step.

Decisions and reasoning
- Built RFM in a separate notebook (`MeteoriteP-RFM.ipynb`) so the finished Meteorite notebook stays as it is.
- Reference date = latest invoice date in the full dataset + 1 day = 10 Dec 2011. Recency is counted back from there.
- Left out the 33 customers whose only transactions were cancellations. Recency only makes sense after a completed purchase, and they never completed one. RFM covers 4,339 customers. The README's headline count of 4,372 stays the same; the RFM section explains the difference.
- Monetary will be net (from `real_customer`, returns subtracted), not gross. Removing cancellation rows doesn't remove the original purchase but only the refund. So summing revenue without the cancellations would count returned items as if they were kept. Net keeps RFM consistent with the revenue definition used in the rest of the project.

Progress and Error logs
- Built `rfm_base` by filtering a filter: `real_orders` (no cancellations) narrowed down to rows with a CustomerID. Checked with `.nunique()`: exactly 4,339 customers, and the cancellation flag has only one value left, so no cancellations slipped through.
- Side finding from the same check: 18,536 of the 22,064 real orders belong to identified customers. That means about 3,500 orders (roughly 16%) were guest checkouts. This puts a number on the guest-checkout recommendation.
- Built `rfm_CID` with one row per customer (4,339 rows): last purchase date and number of distinct orders.
- Customer 12346: one order of about 74,000 units of a single product (about £77,000), cancelled the same day. 

---

## 2026-10-04 (RFM extension, Python / pandas)
Task: Finish the RFM table: add Recency and Monetary next to Frequency, then check everything before scoring.

Learned: `pd.qcut` (equal-sized groups) vs. `pd.cut` (chosen ranges); `qcut` returns ordered categories, so scores need `.astype(int)` before comparisons like `>= 4` behave as numbers; `np.select` as a multi-condition version of `np.where`.

Decisions and reasoning
- Kept the 17 customers with net Monetary of £0 or less. When customers are scored by ranking, they land in the lowest Monetary group automatically. Keeping them also avoids a third customer count to explain (4,372 / 4,339 / 4,322).
- Recency and Monetary scored 1–5 by quintiles (`pd.qcut`). Recency labels are reversed, since fewer days since the last purchase is better.
- Frequency scored with fixed ranges instead of quintiles. About a third of customers (1,494) have exactly one order, so equal-sized groups aren't possible without breaking ties at random, which could give two identical customers different scores. Picked the ranges from the actual distribution so each score has a plain meaning: 1 order, 2, 3–4, 5–9, 10+.
- There are many ways to segment RFM: using all 125 score combinations, adding the three scores into one number, or clustering. Went with a short rule set based on R and F only, a simplified version of the standard RFM segment map: Champions, Loyal, At Risk, New / Promising, Lost, Others. It's easier to explain and to act on. Monetary is left out of the rules on purpose and used afterwards to measure what each segment is worth.

Progress and Error logs
- Recency: reference date minus each customer's last purchase date, in whole days.
- Monetary: net revenue per customer from `real_customer`, matching the Oct 1 decision.
- Sanity checks: customer 14646 has Monetary 279,489.02, an exact match with Meteorite. Customer 12346 is at 0.0, which confirms the cancelled order is netted out. No missing values across all 4,339 customers. 17 customers have Monetary of £0 or less.
- RFM table complete: one row per customer with recency, frequency (`order_count`) and monetary.
- R and M scores: about 868 customers per score. R ranges from 843 to 905 because customers tied on the same day can't be split across two scores.
- The frequency distribution reconciles with earlier work: 1,494 one-time customers means 2,845 repeat customers, matching SQL file 04 exactly. And 1,494 plus the 33 cancellation-only customers gives 1,527, the original one-time count.
- Segments: Lost 1,325, Others 1,092, Champions 837, New / Promising 528, At Risk 383, Loyal 174. Adds up to exactly 4,339. Customer 14646 lands in Champions and 12346 in Lost, as expected.

---

## 2026-10-06 (RFM extension, Python / pandas)
Task: Turn the customer-level segments into a segment-level summary, to see which segments the business actually depends on.

Learned: after a groupby, the grouping key becomes the index rather than a column.

Decisions and reasoning
- Added revenue share and customer share next to each other. Raw revenue only shows which segment made the most money. Comparing the two shares shows how much of the business depends on each segment relative to its size.

Progress and Error logs
- Built `segment_analysis`: one row per segment with customer count, total and average net revenue, average recency, revenue share and customer share.
- Champions: 19.3% of customers, 64.5% of revenue. Average spend about £6,400, last purchase about 12 days ago on average.
- At Risk: 8.8% of customers (383), 6.8% of revenue (about £565,000). Average spend about £1,475, more than three times a Lost customer, but on average they haven't bought in about 137 days.
- Lost: 30.5% of customers, only 7.0% of revenue, average recency about 210 days.
- Revenue is heavily concentrated: Champions and Loyal together are about 23% of customers and about 71% of revenue.

---

## 2026-10-07 (RFM extension, Python / pandas)
Task: Finish the segment analysis: two charts, and work out where to start within the At Risk group.

Learned: grouping summarises rows at a coarser level (product lines → customers → segments), while filtering keeps rows at the same level

Decisions and reasoning
- Within At Risk, ranked customers by net revenue to find where retention effort pays off most. Used the top 20 as a realistic size for personal outreach.

Progress and Error logs
- Chart: customer share vs. revenue share by segment, saved as `charts/rfm_share_by_segment.png`.
- `at_risk`: 383 customers, matching the segment count. Every row has R 1–2 and F 3+, so the segment rule held.
- The top 20 At Risk customers (about 5% of the group) hold 23.4% of its value, about £132,000 of £565,000. Value varies hugely within the group, from about £21,500 down to under £100.
- Notable: customer 15749 is the single most valuable At Risk customer (about £21,500, last order 235 days ago). Customer 16745 placed 17 orders but hasn't bought in 87 days, a frequent buyer who has stopped.
- Chart: top 20 At Risk customers by net revenue, saved as `charts/rfm_top20_at_risk.png`.
- Draft recommendation: personal outreach to the top 20 At Risk customers, a broader targeted campaign for the other 363.

---



