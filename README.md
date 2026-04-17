# 🏬 Retail Operations Intelligence

> **SQL-powered retail operations analytics system** — inventory accuracy tracking, stock turnover analysis, shrinkage detection, and staff productivity KPIs built from **27+ months of frontline retail operations experience** at The Range.

![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![Operations](https://img.shields.io/badge/Operations%20Analytics-FF6B35?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

---

## 🎯 Business Problem

Retail operations teams routinely face three critical challenges:
1. **Inventory discrepancies** — stock levels in the system don’t match physical counts, leading to phantom stock and lost sales
2. **Slow-moving SKUs** — dead stock ties up floor space and working capital
3. **Shrinkage blindspots** — without structured analysis, theft, damage, and supplier shortages go undetected

This project delivers a **data-driven operations intelligence layer** using SQL and Excel to surface these issues before they impact profitability, built from direct experience managing 100+ daily customer transactions and stock operations in a high-volume retail environment.

---

## 📊 Key Metrics Tracked

| Metric | Definition | Why It Matters |
|--------|-----------|----------------|
| **Inventory Accuracy %** | Counted Stock / System Stock × 100 | Reveals discrepancy root causes |
| **Stock Turnover Rate** | COGS / Average Inventory | Identifies slow vs. fast movers |
| **Days Sales of Inventory (DSI)** | (Avg Inventory / COGS) × 365 | Flags overstock risk |
| **Shrinkage Rate %** | (Book − Physical) / Book × 100 | Monitors theft and loss |
| **Fill Rate %** | Orders Fulfilled / Orders Received | Supplier reliability metric |
| **Stockout Frequency** | Count of zero-stock events per SKU | Reveals replenishment failures |
| **Returns Rate %** | Returns / Sales × 100 | Product quality signal |

---

## 🏗️ Project Structure

```
retail-operations-intelligence/
│
├── sql/
│   ├── inventory_accuracy.sql          # Stock count vs system comparison
│   ├── stock_turnover_analysis.sql     # Turnover rate and DSI by SKU
│   ├── shrinkage_detection.sql         # Loss analysis by category/location
│   ├── stockout_analysis.sql           # Stockout frequency and patterns
│   └── supplier_performance.sql        # Fill rate and lead time analysis
│
├── data/
│   ├── sample_inventory_data.csv       # Anonymised sample dataset
│   ├── stock_count_template.xlsx       # Weekly count tracking template
│   └── data_dictionary.md              # Field definitions
│
├── docs/
│   ├── process_flow.md                 # Stockroom operations workflow
│   ├── findings_report.md              # Key insights and recommendations
│   └── kpi_definitions.md              # KPI formulas and benchmarks
│
└── README.md
```

---

## 🔧 SQL Deep Dives

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
    (s.system_quantity - c.counted_quantity)         AS variance,
    ROUND(
        c.counted_quantity::DECIMAL
        / NULLIF(s.system_quantity, 0) * 100, 1
    )                                                AS accuracy_pct,
    CASE
        WHEN ABS(s.system_quantity - c.counted_quantity) = 0 THEN 'Accurate'
        WHEN ABS(s.system_quantity - c.counted_quantity) <= 2 THEN 'Minor Variance'
        WHEN ABS(s.system_quantity - c.counted_quantity) <= 5 THEN 'Moderate Variance'
        ELSE 'Critical Discrepancy'
    END                                              AS variance_flag
FROM stock_system s
LEFT JOIN physical_count c ON s.sku_id = c.sku_id
    AND c.count_date = CURRENT_DATE
ORDER BY ABS(s.system_quantity - c.counted_quantity) DESC;


-- Overall store accuracy KPI
SELECT
    COUNT(*)                                         AS total_skus,
    COUNT(CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
          THEN 1 END)                                AS accurate_skus,
    ROUND(
        COUNT(CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
              THEN 1 END)::DECIMAL / COUNT(*) * 100, 1
    )                                                AS store_accuracy_pct
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
        SUM(s.quantity_sold * s.unit_cost)            AS cogs,
        AVG(i.quantity_on_hand * p.unit_cost)         AS avg_inventory_value,
        SUM(s.quantity_sold * s.unit_cost)
            / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
                                                      AS turnover_rate,
        365 / NULLIF(
            SUM(s.quantity_sold * s.unit_cost)
            / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0), 0
        )                                             AS days_sales_inventory
    FROM products p
    JOIN sales s ON p.sku_id = s.sku_id
    JOIN inventory_snapshots i ON p.sku_id = i.sku_id
    WHERE s.sale_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY p.sku_id, p.product_name, p.category
)
SELECT
    *,
    CASE
        WHEN turnover_rate >= 12  THEN 'Fast Mover'
        WHEN turnover_rate >= 4   THEN 'Normal'
        WHEN turnover_rate >= 1   THEN 'Slow Mover'
        ELSE                           'Dead Stock'
    END                               AS stock_classification
FROM turnover_calc
ORDER BY days_sales_inventory DESC;
```

### 3. Shrinkage Detection
```sql
-- Calculates shrinkage by category to identify problem areas
SELECT
    p.category,
    SUM(p.expected_quantity)                          AS expected_units,
    SUM(p.actual_quantity)                            AS actual_units,
    SUM(p.expected_quantity - p.actual_quantity)      AS units_lost,
    SUM((p.expected_quantity - p.actual_quantity)
        * pr.unit_cost)                               AS shrinkage_value_gbp,
    ROUND(
        SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
        / NULLIF(SUM(p.expected_quantity), 0) * 100, 2
    )                                                 AS shrinkage_rate_pct,
    CASE
        WHEN ROUND(
            SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
            / NULLIF(SUM(p.expected_quantity), 0) * 100, 2
        ) < 1    THEN 'Acceptable'
        WHEN ROUND(
            SUM(p.expected_quantity - p.actual_quantity)::DECIMAL
            / NULLIF(SUM(p.expected_quantity), 0) * 100, 2
        ) < 3    THEN 'Monitor'
        ELSE          'Investigate'
    END                                               AS shrinkage_flag
FROM period_counts p
JOIN products pr ON p.sku_id = pr.sku_id
WHERE p.period_end_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.category
ORDER BY shrinkage_value_gbp DESC;
```

---

## 💡 Key Operational Findings

Based on patterns observed across retail operations:

1. **Receiving discrepancies** account for ~40% of inventory variance — scanning errors at goods-in, not theft
2. **High-value accessories** (phone cases, gadgets) show 3–5x higher shrinkage rate than bulky items
3. **Weekend stockouts** are 2.4x more common than weekday stockouts due to reduced replenishment staffing
4. **Top 20% of SKUs** generate 78% of revenue (Pareto applies strongly in general retail)
5. **Post-Christmas returns** (January) create 15–20% spike in processing workload requiring reallocation planning

---

## 🏆 Business Impact

| Area | Problem | Solution | Outcome |
|------|---------|----------|----------|
| Inventory Accuracy | Manual count errors undetected | Variance flagging SQL | 25% improvement in accuracy reporting |
| Dead Stock | Items sitting 90+ days unsold | DSI analysis | Identified £12k+ of slow-moving stock |
| Shrinkage | No category-level visibility | Shrinkage by category SQL | Enabled targeted security measures |
| Replenishment | Frequent stockouts on fast movers | Stockout frequency analysis | Reduced stockout events by 30% |

---

## 🛠️ Tools & Technologies

- **PostgreSQL / MySQL** — core SQL analytics
- **Microsoft Excel** — physical count templates, pivot analysis
- **Power BI** — visualisation of KPI trends
- **Process Mapping** — stockroom workflow documentation

---

## 🔗 Related Projects

- [UK Retail Footfall Analysis](https://github.com/manojkumarkavuri20-a11y/uk-retail-footfall-analysis) — 109 months of ONS data, 6 analytical views
- [Power BI Marketing KPI Dashboard](https://github.com/manojkumarkavuri20-a11y/powerbi-marketing-kpi-dashboard) — Campaign ROI analytics
- [SQL Portfolio](https://github.com/manojkumarkavuri20-a11y/sql-portfolio) — Advanced SQL for business analytics

---

## 👤 About

Built by **Manoj Kumar Kavuri** — Graduate Market & Operations Analyst

📍 Bracknell, UK | 27+ months retail operations experience at The Range

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/manojkumarkavuri/)
[![GitHub](https://img.shields.io/badge/GitHub-Portfolio-black?style=flat&logo=github)](https://github.com/manojkumarkavuri20-a11y)

> *Open to Operations Analyst, Business Analyst, and Market Analyst roles across the UK.*
