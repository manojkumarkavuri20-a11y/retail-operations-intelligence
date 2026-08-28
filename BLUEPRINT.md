# Blueprint: Retail Operations Intelligence

## Why this repo exists

I spent 27+ months working part-time on the shop floor at The Range, and a lot of that time was spent noticing the same operational problems every retailer deals with: stock counts that don't match the system, shelves full of items nobody is buying, and shrinkage nobody can quite explain. This repo is my attempt to build the kind of SQL layer a retail operations or business analyst would write to catch those problems early, using a synthetic dataset shaped like a real store's inventory data rather than any real employer's numbers.

The project is deliberately SQL-first. Rather than a polished dashboard, it is four focused query files, each answering one operational question end to end, plus documentation that is honest about what is illustrative and what is a genuine data-modelling decision.

## How it's built

Everything runs against plain PostgreSQL 13+, no extensions required. `data/sample_inventory_data.csv` is the one piece of sample data that ships with the repo; the other tables the SQL references (physical counts, period counts, purchase orders, sales, inventory snapshots) are documented in `docs/data_dictionary.md` but not included as CSVs, since the point of this repo is the query logic rather than a bundled database. Anyone who wants to run these queries would stand up a Postgres database, load the sample CSV into `stock_system`, and either generate synthetic data for the remaining tables or adapt the queries to their own schema.

## Module by module

`inventory_accuracy.sql` compares system-recorded stock against physical counts. It produces a SKU-level variance report with a flag ranging from Accurate to Critical Discrepancy, a single store-wide accuracy KPI for management reporting, a category breakdown to focus audit effort, and a week-on-week trend to show whether accuracy is improving or getting worse over time.

`stock_turnover_analysis.sql` calculates turnover rate and Days Sales of Inventory per SKU from ninety days of sales and inventory snapshots, classifying each SKU as a fast mover, normal, slow mover, or dead stock. It rolls that up to a category-level summary for a management dashboard, lists SKUs with zero sales in ninety days as clearance or write-off candidates, and separately calculates a reorder point from recent sales velocity and each SKU's lead time.

`shrinkage_detection.sql` measures the gap between expected and actual stock from periodic counts, broken down by category and by store location and aisle so loss-prevention effort can be targeted at the areas actually driving it. It also tracks the shrinkage rate month over month, surfaces the individual SKUs with the highest absolute loss value, and separately looks at supplier delivery variance, so that a shortfall from a supplier isn't mistaken for in-store shrinkage.

`reorder_alert_report.sql` takes a different angle again: for every SKU it estimates average daily sales, works out days of supply from current stock, and flags anything critical, low, or missing sales data entirely, along with a suggested reorder quantity and its estimated cost. This file was written independently of the other three, against its own `inventory` and `daily_sales` naming rather than `stock_system`.

## A schema inconsistency I chose to document rather than hide

Because these four files were written to answer four separate operational questions at different points, they don't all reach for the same table and column names for what is, in the real world, the same underlying stock data. `inventory_accuracy.sql`, `shrinkage_detection.sql`, and parts of `stock_turnover_analysis.sql` use `stock_system` and `products`; `reorder_alert_report.sql` uses its own `inventory` table with `units_in_stock` and `unit_price` instead of `system_quantity` and `unit_cost`. `docs/data_dictionary.md` documents both namings and explains explicitly that they represent the same real-world entity. I left this as-is rather than quietly reconciling it, because spotting and flagging exactly this kind of schema drift between teams or time periods is the kind of thing a Business Analyst is actually there to catch, and papering over it in the portfolio would hide that rather than demonstrate it.

## Findings and business impact framing

`docs/findings_report.md` and the README's findings sections are explicitly framed as illustrative outputs the queries are designed to produce from the synthetic dataset, not measured results from a real employer. An earlier version of the findings report presented specific figures as if they were real outcomes measured at The Range; I rewrote it so the framing matches the rest of the repo, since the honest and the inflated version can't both be true at once, and honest is the one that actually reflects a portfolio project built on synthetic data.

## What I'd add next

A proper synthetic data generator for the remaining tables (physical counts, purchase orders, sales, inventory snapshots) so the whole pipeline could be run end to end rather than just read. Beyond that, reconciling the `stock_system`/`inventory` schema split into one shared model would be the natural next step, once there's a second consumer of this data that actually needs both files to run against the same database.
