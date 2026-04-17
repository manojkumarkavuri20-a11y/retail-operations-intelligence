-- ============================================================
-- Stock Turnover & Slow Mover Analysis
-- Project: Retail Operations Intelligence
-- Author:  Manoj Kumar Kavuri
-- Description: Calculates stock turnover rate and Days Sales
--              of Inventory (DSI) to classify SKUs as fast
--              movers, slow movers, or dead stock.
-- ============================================================

-- 1. SKU-LEVEL TURNOVER RATE & CLASSIFICATION
WITH turnover_calc AS (
    SELECT
        p.sku_id,
        p.product_name,
        p.category,
        p.unit_cost,
        SUM(s.quantity_sold * s.unit_cost)             AS cogs,
        AVG(i.quantity_on_hand * p.unit_cost)          AS avg_inventory_value,
        SUM(s.quantity_sold)                           AS total_units_sold,
        ROUND(
            SUM(s.quantity_sold * s.unit_cost)
            / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
        , 2)                                           AS turnover_rate,
        ROUND(
            365 / NULLIF(
                SUM(s.quantity_sold * s.unit_cost)
                / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
            , 0)
        , 0)                                           AS days_sales_inventory
    FROM products p
    JOIN sales s
        ON  p.sku_id = s.sku_id
        AND s.sale_date >= CURRENT_DATE - INTERVAL '90 days'
    JOIN inventory_snapshots i
        ON  p.sku_id = i.sku_id
        AND i.snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY p.sku_id, p.product_name, p.category, p.unit_cost
)
SELECT
    sku_id,
    product_name,
    category,
    total_units_sold,
    ROUND(avg_inventory_value, 2)                      AS avg_inventory_value_gbp,
    turnover_rate,
    days_sales_inventory,
    CASE
        WHEN turnover_rate >= 12   THEN 'Fast Mover'
        WHEN turnover_rate >= 4    THEN 'Normal'
        WHEN turnover_rate >= 1    THEN 'Slow Mover'
        WHEN turnover_rate > 0     THEN 'Dead Stock'
        ELSE                            'No Movement'
    END                                                AS stock_classification
FROM turnover_calc
ORDER BY days_sales_inventory DESC NULLS LAST;


-- 2. CATEGORY-LEVEL TURNOVER SUMMARY
-- Used for management dashboard — category health at a glance
SELECT
    p.category,
    COUNT(DISTINCT p.sku_id)                           AS total_skus,
    ROUND(AVG(
        SUM(s.quantity_sold * s.unit_cost)
        / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
    ), 2)                                              AS avg_turnover_rate,
    SUM(
        CASE WHEN (
            SUM(s.quantity_sold * s.unit_cost)
            / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
        ) < 1 THEN 1 ELSE 0 END
    )                                                  AS dead_stock_sku_count,
    ROUND(
        SUM(CASE WHEN (
            SUM(s.quantity_sold * s.unit_cost)
            / NULLIF(AVG(i.quantity_on_hand * p.unit_cost), 0)
        ) < 1 THEN i.quantity_on_hand * p.unit_cost ELSE 0 END
        ), 2
    )                                                  AS dead_stock_value_gbp
FROM products p
JOIN sales s
    ON  p.sku_id = s.sku_id
    AND s.sale_date >= CURRENT_DATE - INTERVAL '90 days'
JOIN inventory_snapshots i
    ON  p.sku_id = i.sku_id
GROUP BY p.category
ORDER BY avg_turnover_rate ASC;


-- 3. DEAD STOCK IDENTIFICATION
-- Lists all SKUs with zero sales in last 90 days
-- These are candidates for clearance or write-off
SELECT
    p.sku_id,
    p.product_name,
    p.category,
    p.date_added,
    CURRENT_DATE - p.date_added                       AS days_in_store,
    i.quantity_on_hand,
    ROUND(i.quantity_on_hand * p.unit_cost, 2)         AS stock_value_gbp,
    COALESCE(s.last_sale_date, p.date_added)           AS last_sale_date,
    CURRENT_DATE - COALESCE(s.last_sale_date, p.date_added)
                                                       AS days_since_last_sale
FROM products p
JOIN inventory_snapshots i
    ON  p.sku_id = i.sku_id
    AND i.snapshot_date = CURRENT_DATE
LEFT JOIN (
    SELECT sku_id, MAX(sale_date) AS last_sale_date
    FROM sales
    GROUP BY sku_id
) s ON p.sku_id = s.sku_id
WHERE i.quantity_on_hand > 0
  AND (
      s.last_sale_date IS NULL
      OR s.last_sale_date < CURRENT_DATE - INTERVAL '90 days'
  )
ORDER BY days_since_last_sale DESC;


-- 4. REORDER POINT ANALYSIS
-- Flags SKUs approaching stockout based on current velocity
WITH daily_velocity AS (
    SELECT
        sku_id,
        ROUND(SUM(quantity_sold)::DECIMAL / 90, 2)     AS avg_daily_sales
    FROM sales
    WHERE sale_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY sku_id
)
SELECT
    p.sku_id,
    p.product_name,
    p.category,
    i.quantity_on_hand                                 AS current_stock,
    dv.avg_daily_sales,
    p.lead_time_days,
    ROUND(dv.avg_daily_sales * p.lead_time_days, 0)    AS reorder_point,
    ROUND(i.quantity_on_hand / NULLIF(dv.avg_daily_sales, 0), 0)
                                                       AS days_of_stock_remaining,
    CASE
        WHEN i.quantity_on_hand <= dv.avg_daily_sales * p.lead_time_days
            THEN 'REORDER NOW'
        WHEN i.quantity_on_hand <= dv.avg_daily_sales * p.lead_time_days * 1.5
            THEN 'Reorder Soon'
        ELSE
            'Sufficient Stock'
    END                                                AS reorder_status
FROM products p
JOIN inventory_snapshots i
    ON  p.sku_id = i.sku_id
    AND i.snapshot_date = CURRENT_DATE
JOIN daily_velocity dv ON p.sku_id = dv.sku_id
ORDER BY days_of_stock_remaining ASC NULLS LAST;
