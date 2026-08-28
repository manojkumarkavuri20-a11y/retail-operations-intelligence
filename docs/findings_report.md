# Findings Report — Retail Operations Intelligence

**Portfolio project built for learning purposes using a synthetic dataset. No employer, client or customer data is used.** The findings below are illustrative outputs the SQL queries in `sql/` are designed to produce, informed by general retail operations concepts and 27+ months of frontline experience at The Range — not measured results from any real employer's data.

**Author:** Manoj Kumar Kavuri | **Organisation referenced for context:** The Range (27+ months frontline retail experience, part-time)

## Executive Summary

This report walks through the kind of structured analysis the SQL queries in this repo are built to support: inventory accuracy, stock turnover, shrinkage, and replenishment patterns for a general merchandise retail environment.

Illustrative headline result: this style of data-driven operations monitoring is designed to lift inventory accuracy, cut stockout frequency, and surface real money tied up in slow-moving stock — the kind of outcome these queries are built to make visible, not a specific measured result from a real deployment.

## 1. Inventory Accuracy

### Illustrative pattern

| Metric | Baseline | After Intervention | Change |
|--------|---------|-------------------|--------|
| Overall Store Accuracy | ~72% | ~90% | +25% |
| Critical Discrepancies (>5 units) | 18% of SKUs | 6% of SKUs | −67% |
| Average Weekly Variance Value | £1,840 | £620 | −66% |

### Root causes the variance query is designed to isolate

Four things typically drive this kind of variance. Receiving errors — items scanned incorrectly at goods-in, usually during high-volume deliveries on Monday and Tuesday mornings — tend to be the largest share; a double-scan protocol for orders over 50 units is the natural fix. Returns misprocessing comes next: returned items re-shelved without a system update create phantom stock, which a mandatory system scan on all returns before reshelving closes off. Transfer errors follow, where stock moves between sections without a system update, especially during seasonal resets, and a section transfer form requirement addresses that directly. What's left after those three is genuine shrinkage, covered in Section 3 below.

### What this points toward

Weekly cycle counts, roughly 20% of SKUs per week on a rotation, would catch these patterns far faster than an annual full count, especially if counts are prioritised on high-value and high-variance categories. A variance dashboard visible to shift managers in real time is the natural next step once the SQL above is running on a schedule.

## 2. Stock Turnover & Slow Movers

### Illustrative pattern

| Classification | % of SKUs | % of Floor Space | % of Revenue |
|---------------|-----------|-----------------|-------------|
| Fast Movers (turnover ≥12) | 22% | 35% | 61% |
| Normal (4–11) | 38% | 40% | 30% |
| Slow Movers (1–3) | 28% | 18% | 8% |
| Dead Stock (<1) | 12% | 7% | 1% |

### What the turnover query is designed to surface

A strong Pareto pattern is typical here: a small share of SKUs generates the large majority of revenue, so fast movers deserve priority replenishment and prominent floor placement. Dead stock tends to tie up real capital in seasonal items that never got cleared after their season — garden furniture in October, Christmas stock in January — and a structured clearance event is the standard response. High days-of-stock tends to concentrate in a handful of categories, home décor and craft being typical candidates for a periodic range review once several months pass with no sale. And a purely historical-average approach to reordering can let a genuinely fast-moving SKU stock out before anyone notices the trend, which is exactly the failure mode this query is built to catch.

### What this points toward

Automated reorder alerts triggered when stock drops below `avg_daily_sales × lead_time_days`, a quarterly dead stock clearance review, and a deliberate narrowing of range width in low-turnover categories — with more depth where the fast movers are — would all follow directly from this analysis.

## 3. Shrinkage Analysis

### Illustrative pattern by category

| Category | Shrinkage Rate | Flag | Suggested Action |
|----------|---------------|------|--------|
| Electronics Accessories | 4.2% | Critical | Security case + weekly count |
| Health & Beauty | 3.1% | Critical | End-aisle placement, locked display |
| Stationery | 2.4% | Investigate | Bi-weekly count |
| Toys | 1.8% | Monitor | Monthly count |
| Garden | 0.6% | Acceptable | Quarterly count |
| Home Decor | 0.3% | Acceptable | Quarterly count |

### What the shrinkage query is designed to surface

Small, high-value items tend to carry disproportionate shrinkage — electronics and beauty categories typically run at several times the rate of bulky or low-price categories, a pattern common across general merchandise retail. There's usually a seasonal peak around Q4, when higher footfall and busier staff coincide with a rise in theft risk, which argues for tighter floor coverage in that window specifically. Not all of the variance is theft, either: a meaningful share can trace back to supplier under-delivery rather than in-store loss, which is exactly why `shrinkage_detection.sql` includes a dedicated supplier delivery variance query rather than treating every book-vs-physical gap as shrinkage. And loss tends to concentrate in a small number of aisles — a handful of high-value aisles can account for the majority of shrinkage value despite holding a small minority of total SKUs.

### What this points toward

Security casing or keeper locks above a chosen unit cost threshold, a formal conversation with the highest-shortfall suppliers using the delivery variance query as evidence, and daily spot counts on flagged aisles during peak season are the natural responses.

## 4. Replenishment & Stockout Analysis

### Illustrative pattern

| Metric | Finding |
|--------|--------|
| Stockout events (90-day period) | dozens of instances across a few dozen SKUs |
| Weekend stockout rate | markedly higher than weekday rate |
| Most common cause | replenishment not triggered before the weekend |
| Average duration of stockout | under two days |
| Estimated lost revenue per stockout | tens to low hundreds of pounds, depending on category |

### What the reorder alert query is designed to surface

Replenishment cadence often lags demand: if most replenishment happens Thursday or Friday on a fixed delivery schedule, fast movers can sell out by Saturday afternoon regardless. Repeat offenders are a sign the reorder point itself is wrong rather than bad luck — a SKU that stocks out more than once in 90 days needs a structural fix, not a one-off top-up. And static historical-average ordering tends to under-serve seasonal or promotional items specifically, since those are exactly the SKUs a simple average-based system will systematically under-order.

### What this points toward

Shifting the replenishment check to Wednesday evening for weekend-critical fast movers, flagging any SKU with three or more stockouts in 90 days for a permanent reorder point uplift, and logging stockouts as part of the daily close-of-play checklist would all follow from this query.

## 5. Summary of Illustrative Business Impact

| Area | Problem Identified | Solution Applied | Illustrative Outcome |
|------|-------------------|-----------------|-------------------|
| Inventory Accuracy | Low accuracy, high variance | Variance SQL monitoring + cycle counts | Meaningful accuracy improvement |
| Dead Stock | Capital tied up in slow movers | DSI analysis + clearance scheduling | Slow-moving stock value identified and actioned |
| Shrinkage | No category-level visibility | Shrinkage detection SQL by category | Targeted security applied to the worst categories |
| Stockouts | Frequent, clustered events | Reorder point analysis | Reduced stockout frequency |
| Supplier Variance | Undetected shortfalls | Supplier delivery variance query | Shortfall suppliers identified for a formal conversation |

## 6. Next Steps

This report and the SQL behind it point to four natural extensions: building a Power BI dashboard so these KPIs are visible to shift managers daily, automating a weekly accuracy report straight from SQL to email, extending the analysis to staff productivity KPIs such as units processed per hour and error rates by operator, and integrating with a live EPoS feed for real-time velocity tracking instead of a periodic snapshot.

---

*Report compiled by Manoj Kumar Kavuri — [LinkedIn](https://www.linkedin.com/in/manojkumarkavuri/) | [GitHub](https://github.com/manojkumarkavuri20-a11y)*
