-- ============================================================
-- Shrinkage Detection & Loss Analysis
-- Project: Retail Operations Intelligence
-- Author:  Manoj Kumar Kavuri
-- Description: Identifies unexplained stock losses by category,
--              location, and time period. Flags areas requiring
--              investigation for theft, damage, or supplier issues.
-- ============================================================

-- 1. SHRINKAGE BY CATEGORY
-- Primary view for loss prevention reporting
SELECT
    pr.category,
    SUM(pc.expected_quantity)                          AS expected_units,
    SUM(pc.actual_quantity)                            AS actual_units,
    SUM(pc.expected_quantity - pc.actual_quantity)     AS units_lost,
    ROUND(
        SUM((pc.expected_quantity - pc.actual_quantity) * pr.unit_cost)
    , 2)                                               AS shrinkage_value_gbp,
    ROUND(
        SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
        / NULLIF(SUM(pc.expected_quantity), 0) * 100
    , 2)                                               AS shrinkage_rate_pct,
    CASE
        WHEN ROUND(
            SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
            / NULLIF(SUM(pc.expected_quantity), 0) * 100
        , 2) < 1    THEN 'Acceptable (<1%)'
        WHEN ROUND(
            SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
            / NULLIF(SUM(pc.expected_quantity), 0) * 100
        , 2) < 2    THEN 'Monitor (1-2%)'
        WHEN ROUND(
            SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
            / NULLIF(SUM(pc.expected_quantity), 0) * 100
        , 2) < 3    THEN 'Investigate (2-3%)'
        ELSE             'Critical Action Required (>3%)'
    END                                                AS shrinkage_flag
FROM period_counts pc
JOIN products pr ON pc.sku_id = pr.sku_id
WHERE pc.period_end_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY pr.category
ORDER BY shrinkage_value_gbp DESC;


-- 2. SHRINKAGE BY STORE LOCATION / AISLE
-- Identifies high-risk physical areas in the store
SELECT
    ss.location,
    ss.aisle,
    COUNT(DISTINCT ss.sku_id)                          AS total_skus,
    SUM(ss.system_quantity - pc.counted_quantity)      AS total_variance,
    ROUND(
        SUM(
            GREATEST(ss.system_quantity - pc.counted_quantity, 0)
            * pr.unit_cost
        ), 2
    )                                                  AS loss_value_gbp,
    ROUND(
        SUM(GREATEST(ss.system_quantity - pc.counted_quantity, 0))::DECIMAL
        / NULLIF(SUM(ss.system_quantity), 0) * 100
    , 2)                                               AS location_shrinkage_pct
FROM stock_system ss
JOIN physical_count pc
    ON  ss.sku_id    = pc.sku_id
    AND pc.count_date = CURRENT_DATE
JOIN products pr ON ss.sku_id = pr.sku_id
GROUP BY ss.location, ss.aisle
HAVING SUM(GREATEST(ss.system_quantity - pc.counted_quantity, 0)) > 0
ORDER BY loss_value_gbp DESC;


-- 3. SHRINKAGE TREND - MONTH OVER MONTH
-- Tracks whether loss prevention efforts are working
WITH monthly_shrinkage AS (
    SELECT
        DATE_TRUNC('month', pc.period_end_date)        AS month,
        SUM(pc.expected_quantity - pc.actual_quantity) AS units_lost,
        ROUND(
            SUM((pc.expected_quantity - pc.actual_quantity) * pr.unit_cost)
        , 2)                                           AS value_lost_gbp,
        ROUND(
            SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
            / NULLIF(SUM(pc.expected_quantity), 0) * 100
        , 2)                                           AS shrinkage_rate_pct
    FROM period_counts pc
    JOIN products pr ON pc.sku_id = pr.sku_id
    GROUP BY DATE_TRUNC('month', pc.period_end_date)
)
SELECT
    month,
    units_lost,
    value_lost_gbp,
    shrinkage_rate_pct,
    LAG(shrinkage_rate_pct) OVER (ORDER BY month)      AS prev_month_rate,
    ROUND(
        shrinkage_rate_pct
        - LAG(shrinkage_rate_pct) OVER (ORDER BY month)
    , 2)                                               AS mom_change_pct
FROM monthly_shrinkage
ORDER BY month DESC;


-- 4. HIGH-VALUE SHRINKAGE ITEMS
-- Surfaces specific SKUs with highest absolute loss value
-- Priority targets for security measures and enhanced counting
SELECT
    pr.sku_id,
    pr.product_name,
    pr.category,
    pr.unit_cost,
    SUM(pc.expected_quantity - pc.actual_quantity)     AS total_units_lost,
    ROUND(
        SUM((pc.expected_quantity - pc.actual_quantity) * pr.unit_cost)
    , 2)                                               AS total_loss_value_gbp,
    ROUND(
        SUM(pc.expected_quantity - pc.actual_quantity)::DECIMAL
        / NULLIF(SUM(pc.expected_quantity), 0) * 100
    , 2)                                               AS item_shrinkage_rate_pct,
    COUNT(DISTINCT pc.period_end_date)                 AS periods_with_loss
FROM period_counts pc
JOIN products pr ON pc.sku_id = pr.sku_id
WHERE pc.period_end_date >= CURRENT_DATE - INTERVAL '90 days'
  AND pc.expected_quantity > pc.actual_quantity
GROUP BY pr.sku_id, pr.product_name, pr.category, pr.unit_cost
ORDER BY total_loss_value_gbp DESC
LIMIT 20;


-- 5. SUPPLIER DELIVERY VARIANCE
-- Distinguishes between in-store shrinkage vs. supplier shortfalls
SELECT
    po.supplier_name,
    COUNT(DISTINCT po.po_id)                           AS total_orders,
    SUM(po.ordered_quantity)                           AS total_ordered,
    SUM(po.received_quantity)                          AS total_received,
    SUM(po.ordered_quantity - po.received_quantity)    AS total_shortfall,
    ROUND(
        SUM(po.ordered_quantity - po.received_quantity)::DECIMAL
        / NULLIF(SUM(po.ordered_quantity), 0) * 100
    , 2)                                               AS supplier_shortfall_pct,
    ROUND(
        SUM((po.ordered_quantity - po.received_quantity) * po.unit_cost)
    , 2)                                               AS shortfall_value_gbp
FROM purchase_orders po
WHERE po.delivery_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY po.supplier_name
HAVING SUM(po.ordered_quantity - po.received_quantity) > 0
ORDER BY shortfall_value_gbp DESC;
