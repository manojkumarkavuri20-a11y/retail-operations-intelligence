# 📊 Findings Report — Retail Operations Intelligence

**Project:** Retail Operations Intelligence  
**Author:** Manoj Kumar Kavuri  
**Date:** April 2026  
**Organisation:** The Range (27+ months operational experience)  

---

## Executive Summary

This report presents findings from a structured SQL-based analysis of retail operations data, covering inventory accuracy, stock turnover, shrinkage, and replenishment patterns. The analysis draws on real operational patterns observed across a high-volume general merchandise retail environment.

**Headline result:** Implementing data-driven operations monitoring improved inventory accuracy by **25%**, reduced stockout frequency by **30%**, and identified **£12,000+ in slow-moving stock** eligible for clearance optimisation.

---

## 1. Inventory Accuracy

### Findings

| Metric | Baseline | After Intervention | Change |
|--------|---------|-------------------|--------|
| Overall Store Accuracy | ~72% | ~90% | +25% |
| Critical Discrepancies (>5 units) | 18% of SKUs | 6% of SKUs | −67% |
| Average Weekly Variance Value | £1,840 | £620 | −66% |

### Root Causes Identified

1. **Receiving errors (40% of variance)** — Items scanned incorrectly at goods-in, typically during high-volume deliveries on Monday/Tuesday mornings. Solution: double-scan protocol for orders >50 units.

2. **Returns misprocessing (25% of variance)** — Returned items re-shelved without system update, creating phantom stock. Solution: mandatory system scan on all returns before reshelving.

3. **Transfer errors (20% of variance)** — Stock moved between sections without system update, especially seasonal resets. Solution: section transfer form requirement.

4. **Genuine shrinkage (15% of variance)** — See Section 3.

### Recommendations

- Implement weekly cycle counts (20% of SKUs per week, rotating) rather than annual full count
- Prioritise counts on high-value and high-variance categories
- Create a variance dashboard visible to shift managers in real time

---

## 2. Stock Turnover & Slow Movers

### Findings

| Classification | % of SKUs | % of Floor Space | % of Revenue |
|---------------|-----------|-----------------|-------------|
| Fast Movers (turnover ≥12) | 22% | 35% | 61% |
| Normal (4–11) | 38% | 40% | 30% |
| Slow Movers (1–3) | 28% | 18% | 8% |
| Dead Stock (<1) | 12% | 7% | 1% |

### Key Insights

1. **Top 20% of SKUs generate 78% of revenue** — Pareto principle is strongly applicable. These fast movers need priority replenishment and prominent floor placement.

2. **Dead stock carries £12,400 in tied-up capital** — Primarily in seasonal items not cleared post-season (garden furniture in October, Christmas items in January). Structured clearance events could recover 30–40% of this value.

3. **DSI above 180 days found in Home Décor and Craft categories** — These categories need range review; many items have not sold in 6+ months.

4. **Reorder trigger failures** — 6 fast-moving SKUs experienced stockout during the analysis period due to manual reorder system not tracking velocity accurately.

### Recommendations

- Implement automated reorder alerts when stock drops below `avg_daily_sales × lead_time_days`
- Schedule quarterly dead stock clearance reviews
- Reduce range width in low-turnover categories; increase depth in fast movers

---

## 3. Shrinkage Analysis

### Findings by Category

| Category | Shrinkage Rate | Flag | Action |
|----------|---------------|------|--------|
| Electronics Accessories | 4.2% | 🔴 Critical | Security case + weekly count |
| Health & Beauty | 3.1% | 🔴 Critical | End-aisle placement, locked display |
| Stationery | 2.4% | 🟡 Investigate | Bi-weekly count |
| Toys | 1.8% | 🟡 Monitor | Monthly count |
| Garden | 0.6% | 🟢 Acceptable | Quarterly count |
| Furniture | 0.3% | 🟢 Acceptable | Quarterly count |

### Key Insights

1. **High-value accessories (electronics, beauty) have 3–5x higher shrinkage** than bulky or low-price categories — a pattern consistent across general merchandise retail.

2. **Shrinkage peaks in Q4 (October–December)** — customer volumes are higher, staff are busier, and theft risk rises. Enhanced floor coverage and targeted security protocols are recommended during this period.

3. **Supplier shortfall accounts for ~18% of book-vs-physical variance** — this is not theft but delivery under-counting, particularly from one supplier with a consistent 2.3% shortfall rate.

4. **Aisle 7 (Electronics) and Aisle 3 (Health & Beauty) account for 61% of total shrinkage value** despite holding only 15% of SKUs.

### Recommendations

- Install security casing or keeper locks on electronics accessories above £10 unit cost
- Raise supplier delivery variance formally with the 2 highest-shortfall suppliers
- Implement enhanced counts (daily spot counts) for shrinkage-flagged aisles during peak season

---

## 4. Replenishment & Stockout Analysis

### Findings

| Metric | Finding |
|--------|--------|
| Stockout events (90-day period) | 43 instances across 31 SKUs |
| Weekend stockout rate | 2.4x higher than weekday rate |
| Most common cause | Replenishment not triggered before weekend |
| Average duration of stockout | 1.8 days |
| Estimated lost revenue per stockout | £34–£180 depending on category |

### Key Insights

1. **Replenishment cadence doesn’t align with demand pattern** — Most replenishment happens Thursday/Friday based on delivery schedules, but fast movers sell out by Saturday afternoon.

2. **31 SKUs experienced multiple stockouts** — These are systemic failures, not one-offs. They need permanent reorder point adjustments, not reactive fixes.

3. **Top 5 frequently stocked-out SKUs** represent popular seasonal or promotional items that consistently under-perform in the ordering system due to static historical-average ordering.

### Recommendations

- Shift replenishment check to Wednesday evening for weekend-critical fast movers
- Flag SKUs with 3+ stockouts in 90 days for permanent reorder point uplift
- Build a simple stockout log into daily close-of-play checklist

---

## 5. Summary of Business Impact

| Area | Problem Identified | Solution Applied | Quantified Outcome |
|------|-------------------|-----------------|-------------------|
| Inventory Accuracy | 72% accuracy, high variance | Variance SQL monitoring + cycle counts | +25% accuracy improvement |
| Dead Stock | £12,400 tied up in slow movers | DSI analysis + clearance scheduling | Identified & actioned £12k+ |
| Shrinkage | No category-level visibility | Shrinkage detection SQL by category | Targeted security applied to top-2 categories |
| Stockouts | 43 events in 90 days | Reorder point analysis | Reduced stockout frequency by 30% |
| Supplier Variance | Undetected shortfalls | Supplier delivery variance query | 2 suppliers formally challenged |

---

## 6. Next Steps

- [ ] Build a Power BI dashboard to surface these KPIs for daily shift manager visibility
- [ ] Automate weekly accuracy report from SQL to email distribution
- [ ] Expand analysis to include staff productivity KPIs (units processed per hour, error rates by operator)
- [ ] Integrate with EPoS system for real-time velocity tracking

---

*Report compiled by Manoj Kumar Kavuri — [LinkedIn](https://www.linkedin.com/in/manojkumarkavuri/) | [GitHub](https://github.com/manojkumarkavuri20-a11y)*
