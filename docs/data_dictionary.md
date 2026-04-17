# Data Dictionary — Retail Operations Intelligence

This document describes every field in the core dataset used across SQL analysis scripts and Power BI reporting.

---

## Table: `inventory`

The primary dataset (`data/sample_inventory_data.csv`) representing a snapshot of in-store stock levels.

| Column | Data Type | Description | Example |
|---|---|---|---|
| `sku_id` | VARCHAR | Unique product identifier (Stock Keeping Unit) | `SKU001` |
| `product_name` | VARCHAR | Full descriptive name of the product | `Phone Case Assorted` |
| `category` | VARCHAR | Top-level product category | `Electronics Accessories` |
| `zone` | CHAR(1) | Store zone / department code (A–F) | `A` |
| `aisle_location` | VARCHAR | Specific aisle within the zone | `Aisle 7` |
| `supplier` | VARCHAR | Name of the supplying company | `TechSupply Co` |
| `unit_price` | DECIMAL(6,2) | Retail selling price in GBP (£) | `4.99` |
| `last_restocked` | DATE | Date the SKU was last replenished (YYYY-MM-DD) | `2025-06-01` |
| `units_in_stock` | INT | Current on-hand quantity at time of snapshot | `48` |

---

## Table: `daily_sales` *(referenced in SQL queries)*

Expected transactional table for time-series sales analysis. Not included in the sample dataset but modelled in SQL scripts.

| Column | Data Type | Description |
|---|---|---|
| `sku_id` | VARCHAR | Foreign key — joins to `inventory.sku_id` |
| `sale_date` | DATE | Date of the sales transaction |
| `units_sold` | INT | Number of units sold on that date |
| `store_id` | VARCHAR | Store branch identifier (for multi-site analysis) |

---

## Zone / Category Mapping

| Zone | Category |
|---|---|
| A | Electronics Accessories |
| B | Health & Beauty |
| C | Stationery |
| D | Toys |
| E | Garden |
| F | Home Decor |

---

## Key Business Metrics Derived

| Metric | Formula | Used In |
|---|---|---|
| **Days of Supply** | `units_in_stock / avg_daily_sales` | `reorder_alert_report.sql` |
| **Shrinkage Rate** | `(expected_units - actual_units) / expected_units` | `shrinkage_detection.sql` |
| **Stock Turnover** | `units_sold / avg_units_in_stock` | `stock_turnover_analysis.sql` |
| **Inventory Accuracy** | `correct_counts / total_counts` | `inventory_accuracy.sql` |

---

## Notes

- All prices are in **GBP (£)**.
- The sample dataset contains **30 SKUs** across **6 categories**.
- `last_restocked` dates range from **2024-11-01** to **2025-09-01**.
- This dictionary should be updated whenever new fields or tables are introduced.

---

*Maintained by Manoj Kumar Kavuri · [GitHub](https://github.com/manojkumarkavuri20-a11y) · [LinkedIn](https://www.linkedin.com/in/manojkumarkavuri/)*
