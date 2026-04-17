-- ============================================================
-- reorder_alert_report.sql
-- Retail Operations Intelligence
-- Purpose: Identify SKUs falling below reorder threshold
--          and generate a prioritised restock alert report
-- Author:  Manoj Kumar Kavuri
-- ============================================================

-- Step 1: Calculate current stock coverage (days of supply)
WITH stock_coverage AS (
  SELECT
    i.sku_id,
    i.product_name,
    i.category,
    i.aisle_location,
    i.supplier,
    i.units_in_stock,
    i.unit_price,
    -- Estimate average daily sales from historical transactions
    COALESCE(AVG(t.units_sold), 0)            AS avg_daily_sales,
    CASE
      WHEN COALESCE(AVG(t.units_sold), 0) = 0 THEN NULL
      ELSE ROUND(i.units_in_stock / AVG(t.units_sold), 1)
    END                                        AS days_of_supply
  FROM inventory i
  LEFT JOIN daily_sales t
         ON i.sku_id = t.sku_id
        AND t.sale_date >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY
    i.sku_id, i.product_name, i.category,
    i.aisle_location, i.supplier,
    i.units_in_stock, i.unit_price
),

-- Step 2: Apply reorder rules
reorder_flags AS (
  SELECT
    sc.*,
    CASE
      WHEN sc.days_of_supply IS NULL         THEN 'NO SALES DATA'
      WHEN sc.days_of_supply <= 3            THEN 'CRITICAL'
      WHEN sc.days_of_supply <= 7            THEN 'LOW'
      WHEN sc.days_of_supply <= 14           THEN 'MONITOR'
      ELSE                                        'OK'
    END AS reorder_status,
    -- Suggested reorder quantity: 30-day cover minus current stock
    GREATEST(
      0,
      ROUND(COALESCE(sc.avg_daily_sales, 0) * 30 - sc.units_in_stock)
    )    AS suggested_reorder_qty,
    ROUND(
      GREATEST(
        0,
        COALESCE(sc.avg_daily_sales, 0) * 30 - sc.units_in_stock
      ) * sc.unit_price, 2
    )    AS estimated_reorder_cost
  FROM stock_coverage sc
)

-- Step 3: Final alert report — only items needing action
SELECT
  rf.sku_id,
  rf.product_name,
  rf.category,
  rf.aisle_location,
  rf.supplier,
  rf.units_in_stock,
  ROUND(rf.avg_daily_sales, 2)   AS avg_daily_sales,
  rf.days_of_supply,
  rf.reorder_status,
  rf.suggested_reorder_qty,
  rf.estimated_reorder_cost
FROM reorder_flags rf
WHERE rf.reorder_status IN ('CRITICAL', 'LOW', 'NO SALES DATA')
ORDER BY
  CASE rf.reorder_status
    WHEN 'CRITICAL'       THEN 1
    WHEN 'NO SALES DATA'  THEN 2
    WHEN 'LOW'            THEN 3
    ELSE 4
  END,
  rf.days_of_supply ASC NULLS LAST;

-- ============================================================
-- Expected output columns:
--   sku_id | product_name | category | aisle_location |
--   supplier | units_in_stock | avg_daily_sales |
--   days_of_supply | reorder_status | suggested_reorder_qty |
--   estimated_reorder_cost
-- ============================================================
