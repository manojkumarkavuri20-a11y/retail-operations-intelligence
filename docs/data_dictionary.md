# Data Dictionary — Retail Operations Intelligence

This document describes the sample dataset and the fuller schema the SQL scripts in `sql/` are written against.

## Table: `stock_system` (the sample dataset)

`data/sample_inventory_data.csv` is a snapshot of in-store stock levels, and its columns match the `stock_system` / `products` tables referenced in `inventory_accuracy.sql`, `shrinkage_detection.sql`, and `stock_turnover_analysis.sql`.

| Column | Data Type | Description | Example |
|---|---|---|---|
| `sku_id` | VARCHAR | Unique product identifier (Stock Keeping Unit) | `SKU001` |
| `product_name` | VARCHAR | Full descriptive name of the product | `Phone Case Assorted` |
| `category` | VARCHAR | Top-level product category | `Electronics Accessories` |
| `location` | CHAR(1) | Store zone / department code (A–F) | `A` |
| `aisle` | VARCHAR | Specific aisle within the location | `Aisle 7` |
| `supplier` | VARCHAR | Name of the supplying company | `TechSupply Co` |
| `unit_cost` | DECIMAL(6,2) | Cost price in GBP (£) | `4.99` |
| `date_added` | DATE | Date the SKU was first added to the range (YYYY-MM-DD) | `2025-06-01` |
| `lead_time_days` | INT | Supplier lead time, used by the reorder point queries | `5` |
| `system_quantity` | INT | Current on-hand quantity per the system, at time of snapshot | `48` |

## Tables referenced in SQL but not included in the sample dataset

The four SQL scripts model a few more tables beyond the one CSV shipped in `data/`. They are not included as sample data, but every column below is used somewhere in `sql/`, so this is what you would need to stand up to run the queries end to end.

`physical_count` — the result of a manual stock count, used in `inventory_accuracy.sql` and `shrinkage_detection.sql`: `sku_id`, `counted_quantity`, `count_date`, `counted_by`.

`period_counts` — a periodic (e.g. monthly) stock count used specifically for shrinkage measurement in `shrinkage_detection.sql`: `sku_id`, `category`, `expected_quantity`, `actual_quantity`, `period_end_date`.

`purchase_orders` — supplier order and delivery records, used in `shrinkage_detection.sql` to separate supplier shortfalls from in-store shrinkage: `po_id`, `supplier_name`, `ordered_quantity`, `received_quantity`, `unit_cost`, `delivery_date`.

`daily_sales` / `sales` — a sales transaction log, used in `reorder_alert_report.sql` (as `daily_sales`, with a `units_sold` column) and `stock_turnover_analysis.sql` (as `sales`, with a `quantity_sold` column): `sku_id`, `sale_date`, `units_sold` or `quantity_sold`, `unit_cost`.

`inventory_snapshots` — a point-in-time stock snapshot used in `stock_turnover_analysis.sql`, distinct from the live `stock_system` figure: `sku_id`, `snapshot_date`, `quantity_on_hand`.

`inventory` — `reorder_alert_report.sql` was written against its own inventory table, with `units_in_stock` and `unit_price` in place of `stock_system`'s `system_quantity` and `unit_cost`, and `aisle_location` in place of `location` + `aisle`. It represents the same real-world stock levels as `stock_system`, just under a different name.

## A note on schema consistency

These four SQL files were written to answer four different operational questions, and each one reaches for tables and column names slightly differently — `stock_system` versus `inventory`, `daily_sales.units_sold` versus `sales.quantity_sold`. In a real production environment these would need to be consolidated onto one shared schema before all four could run against the same database. Left as-is here deliberately: reconciling it is exactly the kind of schema audit a Business Analyst would flag when queries from different teams or different points in time need to be brought together, and papering over it would hide rather than demonstrate that skill.

## Zone / Category Mapping

| Location | Category |
|---|---|
| A | Electronics Accessories |
| B | Health & Beauty |
| C | Stationery |
| D | Toys |
| E | Garden |
| F | Home Decor |

## Key Business Metrics Derived

| Metric | Formula | Used In |
|---|---|---|
| **Days of Supply** | `units_in_stock / avg_daily_sales` | `reorder_alert_report.sql` |
| **Shrinkage Rate** | `(expected_units - actual_units) / expected_units` | `shrinkage_detection.sql` |
| **Stock Turnover** | `units_sold / avg_units_in_stock` | `stock_turnover_analysis.sql` |
| **Inventory Accuracy** | `correct_counts / total_counts` | `inventory_accuracy.sql` |

## Notes

All prices are in GBP (£). The sample dataset contains 30 SKUs across 6 categories. `date_added` values range from 2024-11-01 to 2025-09-01. This dictionary should be updated whenever new fields or tables are introduced.

---

*Maintained by Manoj Kumar Kavuri · [GitHub](https://github.com/manojkumarkavuri20-a11y) · [LinkedIn](https://www.linkedin.com/in/manojkumarkavuri/)*
