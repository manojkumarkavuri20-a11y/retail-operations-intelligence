# Retail Operations Intelligence

**Portfolio project built for learning purposes using a synthetic dataset. No employer, client or customer data is used.**

**SQL-powered retail operations analytics system** — inventory accuracy tracking, stock turnover analysis, shrinkage detection, and reorder alerting. Built with a synthetic inventory dataset, modelled on retail operations concepts I have practised during 27+ months of frontline retail experience at The Range.

![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![Operations](https://img.shields.io/badge/Operations%20Analytics-FF6B35?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

---

## Business Problem

Retail operations teams routinely face three critical challenges. Inventory discrepancies happen when stock levels in the system don't match physical counts, leading to phantom stock and lost sales. Slow-moving SKUs tie up floor space and working capital as dead stock. And without structured analysis, shrinkage blindspots let theft, damage, and supplier shortages go undetected.

This project delivers a data-driven operations intelligence layer using SQL to surface these issues before they impact profitability, built as a self-initiated exercise to practise the kind of analysis that supports 100+ daily customer transactions and stock operations in a high-volume retail environment.

---

## Key Metrics Tracked

| Metric | Definition | Why It Matters |
|--------|-----------|----------------|
| **Inventory Accuracy %** | Counted Stock / System Stock × 100 | Reveals discrepancy root causes |
| **Stock Turnover Rate** | COGS / Average Inventory | Identifies slow vs. fast movers |
| **Days Sales of Inventory (DSI)** | (Avg Inventory / COGS) × 365 | Flags overstock risk |
| **Shrinkage Rate %** | (Expected − Actual) / Expected × 100 | Monitors theft and loss |
| **Days of Supply** | Units in Stock / Avg Daily Sales | Flags reorder timing |
| **Stockout Frequency** | Count of zero-stock events per SKU | Reveals replenishment failures |

---

## Project Structure

```
retail-operations-intelligence/

sql/
  inventory_accuracy.sql        Stock count vs system comparison
  stock_turnover_analysis.sql   Turnover rate and DSI by SKU
  shrinkage_detection.sql       Loss analysis by category
  reorder_alert_report.sql      Reorder point and safety stock alerts

data/
  sample_inventory_data.csv     Synthetic sample dataset

docs/
  data_dictionary.md            Field definitions and schema notes
  findings_report.md            Illustrative insights and recommendations

README.md
```

---

## SQL Deep Dives

### 1. Inventory Accuracy Analysis
```sql
-- Identifies which SKUs have the largest discrepancy
-- between system records and physical count
SELECT
s.sku_id,
s.product_name,
s.category,
s.location,
s.system_quantity,
c.counted_quantity,
(s.system_quantity - c.counted_quantity) AS variance,
ROUND(
c.counted_quantity::DECIMAL
/ NULLIF(s.system_quantity, 0) * 100, 1
) AS accuracy_pct,
CASE
WHEN ABS(s.system_quantity - c.counted_quantity) = 0 THEN 'Accurate'
WHEN ABS(s.system_quantity - c.counted_quantity) <= 2 THEN 'Minor Variance'
WHEN ABS(s.system_quantity - c.counted_quantity) <= 5 THEN 'Moderate Variance'
ELSE 'Critical Discrepancy'
END AS variance_flag
FROM stock_system s
LEFT JOIN physical_count c ON s.sku_id = c.sku_id
AND c.count_date = CURRENT_DATE
ORDER BY ABS(s.system_quantity - c.counted_quantity) DESC;

-- Overall store accuracy KPI
SELECT
COUNT(*) AS total_skus,
COUNT(CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
THEN 1 END) AS accurate_skus,
ROUND(
COUNT(CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
THEN 1 END)::DECIMAL / COUNT(*) * 100, 1
) AS store_accuracy_pct
FROM stock_system s
JOIN physical_count c ON s.sku_id = c.sku_id
WHERE c.count_date = CURRENT_DATE;
```

### 2. Stock Turnover & Slow Movers
```sql
-- Identifies fast movers vs. dead stock by category
WITH turnover_calc AS (
SELECT
p.sku_id,
p.product_name,
p.category,
SUM(s.quantity_sold * s.unit_cost) AS cogs,
AVG(i.quantity_on_hand * p.unit_cost) AS avg_inventory_value,
SUM(s.quantity_sold * s.unit_cost)
/ NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
AS turnover_rate,
365 / NULLIF(
SUM(s.quantity_sold * s.unit_cost)
/ NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0), 0
) AS days_sales_inventory
FROM products p
JOIN sales s ON p.sku_id = s.sku_id
JOIN inventory_snapshots i ON p.sku_id = i.sku_id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY p.sku_id, p.product_name, p.category
)
SELECT
*,
CASE
WHEN turnover_rate >= 12 THEN 'Fast Mover'
WHEN turnover_rate >= 4 THEN 'Normal'
WHEN turnover_rate >= 1 THEN 'Slow Mover'
ELSE 'Dead Stock'
END AS stock_classification
FROM turnover_calc
ORDER BY days_sales_inventory DESC;
```

### 3. Shrinkage Detection
```sql
-- Calculates shrinkage by category to identify problem areas
SELECT
p.category,
SUM(p.expected_quantity) AS expected_units,
SUM(p.actual_quantity) AS actual_units,
SUM(p.expected_quantity - p.actual_quantity) AS units_lost,
SUM((p.expected_quantity - p.actual_quantity)
* pr.unit_cost) AS shrinkage_value_gbp,
ROUND(
SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
/ NULLIF(SUM(p.expected_quantity), 0) * 100, 2
) AS shrinkage_rate_pct,
CASE
WHEN ROUND(
SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
/ NULLIF(SUM(p.expected_quantity), 0) * 100, 2
) < 1 THEN 'Acceptable'
WHEN ROUND(
SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
/ NULLIF(SUM(p.expected_quantity), 0) * 100, 2
) < 3 THEN 'Monitor'
ELSE 'Investigate'
END AS shrinkage_flag
FROM period_counts p
JOIN products pr ON p.sku_id = pr.sku_id
WHERE p.period_end_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.category
ORDER BY shrinkage_value_gbp DESC;
```

---

## Illustrative Findings from Synthetic Data

These are illustrative patterns the queries are designed to surface, generated from the synthetic dataset, not measured results from a real store. Receiving discrepancies can account for a large share of inventory variance, pointing to scanning errors at goods-in rather than theft. High-value accessories such as phone cases and small gadgets can show a materially higher shrinkage rate than bulky items. Weekend stockouts can be more common than weekday stockouts due to reduced replenishment staffing. The top 20% of SKUs can generate a disproportionate share of revenue, a Pareto pattern common across general retail. And post-Christmas returns in January can create a spike in processing workload that requires reallocation planning.

---

## Illustrative Business Impact

This table shows the kind of before/after comparison the queries are designed to support, based on the synthetic dataset, not real, measured results from an employer.

| Area | Problem | Solution | Illustrative Outcome |
|------|---------|----------|----------|
| Inventory Accuracy | Manual count errors undetected | Variance flagging SQL | Improved accuracy reporting |
| Dead Stock | Items sitting 90+ days unsold | DSI analysis | Surfaces slow-moving stock value |
| Shrinkage | No category-level visibility | Shrinkage by category SQL | Enables targeted security measures |
| Replenishment | Frequent stockouts on fast movers | Reorder alert analysis | Reduces stockout events |

---

## Tools & Technologies

PostgreSQL is used for the core SQL analytics, with the queries designed to run against plain PostgreSQL 13+ with no extensions required. Microsoft Excel and Power BI are named above as the tools I use elsewhere in this portfolio for physical count templates and KPI visualisation, though this particular repository is SQL-only.

---

## Related Projects

[UK Retail Sales & Category Performance Analysis](https://github.com/manojkumarkavuri20-a11y/uk-retail-footfall-analysis) covers 109 months of ONS data across 6 analytical views. [Power BI Marketing KPI Dashboard](https://github.com/manojkumarkavuri20-a11y/powerbi-marketing-kpi-dashboard) covers campaign ROI analytics. [SQL Portfolio](https://github.com/manojkumarkavuri20-a11y/sql-portfolio) covers advanced SQL for business analytics.

---

## About

Built by **Manoj Kumar Kavuri** — Graduate Market & Operations Analyst, based in Bracknell, UK, with a background of 27+ months in frontline retail operations (The Range, part-time).

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/manojkumarkavuri/)
[![GitHub](https://img.shields.io/badge/GitHub-Portfolio-black?style=flat&logo=github)](https://github.com/manojkumarkavuri20-a11y)

*Open to Operations Analyst, Business Analyst, and Market Analyst roles across the UK.*

## Getting Started

To run these queries locally you'll need PostgreSQL 13+ installed.

```bash
# Create the database
psql -U postgres -c "CREATE DATABASE retail_ops;"

# Import sample inventory data
psql -U postgres -d retail_ops -c "\copy stock_system FROM 'data/sample_inventory_data.csv' CSV HEADER;"

# Run your first query
psql -U postgres -d retail_ops -f sql/inventory_accuracy.sql
```

See `docs/data_dictionary.md` for full column definitions and for notes on the additional tables the SQL files reference beyond the sample CSV. Start with `inventory_accuracy.sql` to get a feel for the data structure, then move on to `stock_turnover_analysis.sql` and `shrinkage_detection.sql`.
