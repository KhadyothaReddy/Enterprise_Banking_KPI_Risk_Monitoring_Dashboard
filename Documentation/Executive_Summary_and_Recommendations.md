# Executive Summary & Business Recommendations
## Apex Capital Bank — Enterprise KPI & Risk Monitoring Dashboard
**Prepared For:** Executive Leadership Committee  
**Prepared By:** Business Intelligence & Analytics Division  
**Date:** May 2026  
**Classification:** Internal — Confidential

---

## 1. Project Overview

The Enterprise KPI & Risk Monitoring Dashboard is a consolidation of Apex Capital Bank's performance data into a single, daily-refreshed analytics environment. This initiative was initiated in response to fragmented reporting, 3–4 day data lags, and the absence of a unified risk monitoring layer.

The solution spans:
- **7 integrated datasets** covering 155,000+ records across customers, loans, transactions, branches, credit cards, and fraud activity
- **4 Power BI dashboards** — Executive, Risk, Operations, and Customer Insights
- **SQL analytics layer** with stored procedures, KPI queries, and data quality controls
- **Python modeling layer** with EDA, fraud analysis, K-Means segmentation, and 6-month forecasting

---

## 2. Key Findings from the Data

### 2.1 Portfolio Health

The active loan portfolio shows an NPL ratio of approximately **9.85%** in the synthetic dataset — this is intentionally higher than industry norms to create meaningful risk analysis scenarios. In a real deployment, the target is ≤1.8%.

Mortgage and Personal Loans represent the largest share of outstanding balance. Auto Loans show the highest delinquency rates by count, consistent with industry trends post-2022 as rising rates increased auto payment stress.

### 2.2 Fraud Exposure

- **477 fraud flags** were raised over the analysis period
- **194 confirmed fraud cases** — a 40.7% confirmation rate
- **Total confirmed losses: $1.26M**
- Card Not Present fraud is the highest-volume category
- ML Model-based detection shows the highest precision of the four detection methods — this supports the business case for expanding ML coverage

### 2.3 Branch Performance

Branch deposit attainment varies significantly across regions. The Southeast region has the widest spread — some branches hitting 115%+ of target while others trail at 78%. This divergence points to coaching and resource allocation opportunities rather than purely market-driven factors.

### 2.4 Customer Segmentation

K-Means clustering identified 4 natural customer behavioral segments:

| Cluster | Customers | Profile | Priority Action |
|---------|-----------|---------|----------------|
| Premium / Multi-Product | 6,284 | High credit score, 3+ products, high digital | Retain, upsell premium services |
| Stable Core Customer | 3,765 | Moderate credit, 2 products, mixed digital | Cross-sell digital tools |
| Developing / Building Credit | 801 | Lower credit, 1–2 products | Credit builder programs |
| High Risk / Low Engagement | 4,150 | Low credit score, 1 product, low digital | Monitor, proactive risk outreach |

### 2.5 Digital Adoption

Digital transaction adoption is running around **67%** — above the 65% internal target but with significant regional variation. The South and Midwest regions lag the national average, suggesting targeted digital onboarding campaigns would have outsized ROI in those markets.

---

## 3. Business Recommendations

### Recommendation 1 — Deploy Fraud ML Scoring to 100% of Wire Transfers
**Priority: High | Owner: Fraud Operations**

Wire transfers represent a disproportionate share of confirmed fraud losses despite being a small % of total volume. Currently ML scoring covers approximately 30% of transactions. Expanding full ML coverage to wire transfers and large ACH transfers should reduce confirmed losses by an estimated 15–20%.

*Estimated annual impact: $189K–$252K in reduced fraud losses.*

### Recommendation 2 — Implement 30-Day Delinquency Early Warning for Auto Loans
**Priority: High | Owner: Risk Analytics + Collections**

Auto loans are showing accelerating 30-59 DPD entries in Q1 2026. Early outreach at the 15-day mark (pre-30 DPD) has been shown in industry studies to reduce eventual default rates by 20–35%. Collections team should receive a weekly extract from the dashboard flagging accounts approaching 30 DPD.

*Estimated annual impact: Prevents 0.3–0.5 percentage point increase in NPL ratio.*

### Recommendation 3 — High-Utilization Credit Card Proactive Program
**Priority: Medium | Owner: Relationship Management**

The data shows 1,547 active credit card accounts above 80% utilization. These accounts are statistically 4.2x more likely to miss a payment within 90 days. A proactive outreach program — balance transfer offer, credit limit review, or financial wellness call — targeted at this group is expected to reduce charge-off rates.

*Estimated annual impact: $800K–$1.2M in reduced charge-offs.*

### Recommendation 4 — Branch Performance Coaching Program (Bottom Quartile)
**Priority: Medium | Owner: Regional Retail Banking Managers**

The bottom quartile of branches (20 branches) averages 81% deposit attainment vs 107% for the top quartile. The gap is too large to attribute solely to market factors. A structured 90-day performance improvement program — drawing from the playbook of top-performing branches in comparable markets — should narrow this gap.

*Estimated annual impact: 8–12% deposit growth lift in underperforming branches.*

### Recommendation 5 — Accelerate Digital Adoption in South and Midwest Regions
**Priority: Low-Medium | Owner: Digital Banking Team**

South and Midwest regions show 58–61% digital adoption vs 71% in the West and Northeast. Digital transactions cost the bank 60–70% less than branch transactions. A targeted digital onboarding campaign (e-statement conversion, mobile deposit tutorials, push notifications) in these two regions has a clear ROI.

*Estimated annual impact: $2.1M–$3.4M in operating cost reduction if adoption reaches 68%.*

---

## 4. Reporting Impact Achieved

| Metric | Before | After |
|--------|--------|-------|
| Reporting cycle time | 3–4 days | Daily (T+1) |
| Manual compilation hours/month | ~120 hours | ~5 hours (QA only) |
| KPI definitions aligned | No (6 versions of "NIM") | Yes (single documented source) |
| Fraud detection time (avg) | 14 days | Target: ≤5 days |
| Executive dashboard availability | Weekly PDF email | Daily Power BI (web + desktop) |

---

## 5. Next Steps (V2.0 Roadmap)

| Initiative | Target Quarter |
|-----------|---------------|
| Real-time transaction streaming (Apache Kafka → Power BI) | Q3 2026 |
| Automated fraud alert emails (Power BI + Power Automate) | Q3 2026 |
| Credit risk scoring model (Logistic Regression / XGBoost) | Q4 2026 |
| Mobile app analytics integration | Q4 2026 |
| Regulatory reporting automation (Call Report data) | Q1 2027 |

---

*This document was prepared by the Business Intelligence & Analytics Division. Findings are based on synthetic data generated for analytics development purposes. Business recommendations are framework-based and should be validated against live production data before implementation.*
