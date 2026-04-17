-- ============================================================
-- Inventory Accuracy Analysis
-- Project: Retail Operations Intelligence
-- Author:  Manoj Kumar Kavuri
-- Description: Compares system stock vs physical count to
--              identify discrepancies, flag critical SKUs,
--              and calculate overall store accuracy KPI.
-- ============================================================

-- 1. SKU-LEVEL VARIANCE REPORT
-- Identifies which SKUs have the largest discrepancy
-- between system records and physical count
SELECT
    s.sku_id,
    s.product_name,
    s.category,
    s.location,
    s.supplier,
    s.system_quantity,
    c.counted_quantity,
    (s.system_quantity - c.counted_quantity)         AS variance,
    ABS(s.system_quantity - c.counted_quantity)      AS abs_variance,
    ROUND(
        c.counted_quantity::DECIMAL
        / NULLIF(s.system_quantity, 0) * 100, 1
    )                                                AS accuracy_pct,
    CASE
        WHEN ABS(s.system_quantity - c.counted_quantity) = 0
            THEN 'Accurate'
        WHEN ABS(s.system_quantity - c.counted_quantity) <= 2
            THEN 'Minor Variance'
        WHEN ABS(s.system_quantity - c.counted_quantity) <= 5
            THEN 'Moderate Variance'
        ELSE
            'Critical Discrepancy'
    END                                              AS variance_flag,
    c.count_date,
    c.counted_by
FROM stock_system s
LEFT JOIN physical_count c
    ON  s.sku_id     = c.sku_id
    AND c.count_date = CURRENT_DATE
ORDER BY ABS(s.system_quantity - c.counted_quantity) DESC;


-- 2. OVERALL STORE ACCURACY KPI
-- Single headline metric for management reporting
SELECT
    c.count_date,
    COUNT(*)                                          AS total_skus_counted,
    COUNT(
        CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
             THEN 1 END
    )                                                 AS accurate_skus,
    COUNT(
        CASE WHEN ABS(s.system_quantity - c.counted_quantity) BETWEEN 1 AND 2
             THEN 1 END
    )                                                 AS minor_variance_skus,
    COUNT(
        CASE WHEN ABS(s.system_quantity - c.counted_quantity) > 5
             THEN 1 END
    )                                                 AS critical_skus,
    ROUND(
        COUNT(
            CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
                 THEN 1 END
        )::DECIMAL / COUNT(*) * 100, 1
    )                                                 AS store_accuracy_pct
FROM stock_system s
JOIN physical_count c ON s.sku_id = c.sku_id
WHERE c.count_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY c.count_date
ORDER BY c.count_date DESC;


-- 3. ACCURACY BY CATEGORY
-- Identifies which product categories have worst accuracy
-- Helps focus audit efforts where they matter most
SELECT
    s.category,
    COUNT(*)                                          AS total_skus,
    ROUND(AVG(ABS(s.system_quantity - c.counted_quantity)), 1)
                                                      AS avg_variance,
    ROUND(
        SUM(
            CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
                 THEN 1 ELSE 0 END
        )::DECIMAL / COUNT(*) * 100, 1
    )                                                 AS category_accuracy_pct,
    SUM(ABS(s.system_quantity - c.counted_quantity) * s.unit_cost)
                                                      AS total_variance_value_gbp
FROM stock_system s
JOIN physical_count c
    ON  s.sku_id     = c.sku_id
    AND c.count_date = CURRENT_DATE
GROUP BY s.category
ORDER BY category_accuracy_pct ASC;


-- 4. TREND ANALYSIS - Accuracy Over Time
-- Monitors whether stock accuracy is improving or declining
WITH weekly_accuracy AS (
    SELECT
        DATE_TRUNC('week', c.count_date)              AS week_start,
        ROUND(
            SUM(
                CASE WHEN ABS(s.system_quantity - c.counted_quantity) = 0
                     THEN 1 ELSE 0 END
            )::DECIMAL / COUNT(*) * 100, 1
        )                                             AS accuracy_pct
    FROM stock_system s
    JOIN physical_count c ON s.sku_id = c.sku_id
    WHERE c.count_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY DATE_TRUNC('week', c.count_date)
)
SELECT
    week_start,
    accuracy_pct,
    LAG(accuracy_pct) OVER (ORDER BY week_start)     AS prev_week_accuracy,
    ROUND(
        accuracy_pct
        - LAG(accuracy_pct) OVER (ORDER BY week_start), 1
    )                                                 AS week_on_week_change
FROM weekly_accuracy
ORDER BY week_start;
