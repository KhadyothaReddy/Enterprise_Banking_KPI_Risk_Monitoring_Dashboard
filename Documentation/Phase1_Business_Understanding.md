# Phase 1 — Business Understanding
## Apex Capital Bank | Enterprise KPI & Risk Monitoring Initiative
**Document Type:** Business Understanding & Project Charter  
**Prepared By:** Analytics & Strategy Team — Business Intelligence Division  
**Version:** 1.0  
**Date:** May 2026  
**Status:** Approved

---

## 1. Background & Business Context

Apex Capital Bank (ACB) is a mid-to-large commercial and retail bank operating across 12 states in the US, with roughly 3.4 million active customers, 180+ branch locations, and a growing digital banking segment. As of Q1 2026, ACB manages approximately $48 billion in total assets.

Over the past two years, leadership has flagged a recurring problem: **the bank's performance data is fragmented across at least 6 different internal systems** — core banking, CRM, loan origination, risk management, fraud detection, and branch ops. Executives receive weekly reports in static Excel files, often arriving 2–3 days late, and the data quality across these reports is inconsistent enough that it frequently triggers follow-up meetings just to reconcile numbers.

The CFO's office, the Chief Risk Officer, and the Head of Retail Banking jointly escalated this to the Business Intelligence team in Q4 2025. The ask was straightforward: **"Give us a single, trusted source of truth for the metrics we care about."**

This project — the Enterprise KPI & Risk Monitoring Dashboard — is the BI team's response to that ask.

---

## 2. Business Problem Statement

> *"Apex Capital Bank's leadership lacks a consolidated, real-time view of operational performance, customer risk exposure, and branch-level efficiency. Decisions are being made on stale, manually compiled data, and the organization has no early-warning system for emerging risk trends or fraud patterns."*

**Specific pain points that triggered this initiative:**

- **Reporting lag:** KPIs like loan delinquency rate and deposit growth are reported weekly but are 3–4 days stale by the time they reach the CRO.
- **No fraud early-warning:** The fraud team is reacting to confirmed fraud rather than catching patterns before losses escalate.
- **Branch performance opacity:** Regional managers don't have standardized metrics to compare branch performance. Each branch reports differently.
- **Customer segmentation gap:** Relationship managers have no reliable segmentation of customer profitability — high-value customers are often treated the same as low-value ones.
- **Risk concentration blind spot:** The risk team struggles to monitor geographic and product-level risk concentration in near real-time.

---

## 3. Project Objectives

| # | Objective | Priority | Owner |
|---|-----------|----------|-------|
| 1 | Consolidate KPI reporting into a single dashboard environment | High | BI Lead |
| 2 | Build a fraud and risk monitoring layer with trend alerts | High | Risk Analytics |
| 3 | Create branch-level performance benchmarking capability | Medium | Retail Banking |
| 4 | Enable customer segmentation by profitability and risk tier | Medium | CRM Analytics |
| 5 | Reduce reporting lag from 3–4 days to near-real-time (daily refresh) | High | Data Engineering |
| 6 | Establish a single, documented data dictionary for all KPIs | Medium | BI Team |

---

## 4. Stakeholders

### Primary Stakeholders (Direct Users)

| Role | Name (Fictional) | Interest |
|------|-----------------|----------|
| Chief Financial Officer | Michael Hargrove | Profitability KPIs, cost efficiency, NIM |
| Chief Risk Officer | Sandra Voss | Risk exposure, delinquency rates, fraud flags |
| Head of Retail Banking | David Chen | Branch performance, deposit growth, customer acquisition |
| VP of Operations | Renata Okafor | Operational efficiency, SLA adherence, headcount metrics |

### Secondary Stakeholders (Consumers)

| Role | Interest |
|------|----------|
| Regional Branch Managers | Branch-level KPI comparison |
| Relationship Managers | Customer tier and product usage |
| Compliance & Audit Team | Transaction monitoring, regulatory flags |
| Data Engineering Team | Pipeline health, data quality metrics |

### Project Team (BI & Analytics)

| Role | Responsibility |
|------|---------------|
| Senior Business Analyst | Requirements gathering, KPI definition, documentation |
| Data Analyst | Data cleaning, EDA, Python analytics |
| BI Developer | Power BI model, DAX measures, dashboard layout |
| Data Engineer | SQL pipelines, schema design, stored procedures |

---

## 5. Key Business Questions

The dashboard must answer the following questions — these were gathered from stakeholder interviews in November 2025:

### Executive / CFO Questions
1. What is our current Net Interest Margin and how is it trending quarter-over-quarter?
2. Which product lines (loans, credit cards, deposits) are contributing most to revenue?
3. Where are we seeing cost overruns at the branch level?

### Risk & Compliance Questions
4. What is the current loan delinquency rate broken down by product type and region?
5. How many accounts have triggered fraud flags in the last 30 days, and what's the pattern?
6. Which customer segments carry the highest credit risk concentration?
7. Are there geographic clusters where defaults are increasing?

### Retail Banking Questions
8. Which branches are outperforming or underperforming on deposit targets?
9. What is the customer acquisition rate vs. churn rate by region?
10. How are credit card utilization rates trending by customer segment?

### Operations Questions
11. What is the average loan processing time and which branches are causing bottlenecks?
12. What is the SLA adherence rate for customer service requests?
13. How is headcount efficiency (revenue per employee) tracking across regions?

---

## 6. KPI Framework

### 6.1 Financial KPIs

| KPI | Definition | Target | Reporting Frequency |
|-----|-----------|--------|-------------------|
| Net Interest Margin (NIM) | (Interest Income - Interest Expense) / Avg Earning Assets | ≥ 3.2% | Monthly |
| Return on Assets (ROA) | Net Income / Total Assets | ≥ 1.1% | Quarterly |
| Return on Equity (ROE) | Net Income / Shareholders' Equity | ≥ 12% | Quarterly |
| Loan-to-Deposit Ratio (LDR) | Total Loans / Total Deposits | 70–80% | Monthly |
| Cost-to-Income Ratio | Operating Expenses / Operating Income | ≤ 58% | Monthly |
| Revenue per Branch | Total Revenue / Number of Branches | Internal benchmark | Monthly |

### 6.2 Risk KPIs

| KPI | Definition | Target | Reporting Frequency |
|-----|-----------|--------|-------------------|
| Loan Delinquency Rate | Loans 30+ Days Past Due / Total Loans | ≤ 2.5% | Weekly |
| Non-Performing Loan Ratio (NPL) | NPLs / Total Loan Portfolio | ≤ 1.8% | Monthly |
| Credit Loss Provision Rate | Provision for Credit Losses / Total Loans | ≤ 1.2% | Quarterly |
| Fraud Transaction Rate | Flagged Fraud Txns / Total Txns | ≤ 0.08% | Daily |
| Risk-Weighted Asset Ratio | RWA / Total Assets | Monitor | Quarterly |
| Customer Default Rate | Defaulted Accounts / Total Active Accounts | ≤ 1.0% | Monthly |

### 6.3 Operational KPIs

| KPI | Definition | Target | Reporting Frequency |
|-----|-----------|--------|-------------------|
| Loan Processing Time (avg days) | Date Approved - Date Applied | ≤ 7 days | Weekly |
| Branch Transaction Volume | Total Txns per Branch per Month | Benchmark vs. peers | Monthly |
| Customer Acquisition Rate | New Customers / Prior Period Customers | ≥ 2% MoM | Monthly |
| Customer Churn Rate | Closed Accounts / Total Accounts | ≤ 1.5% MoM | Monthly |
| Digital Adoption Rate | Digital Txns / Total Txns | ≥ 65% | Monthly |
| SLA Adherence | Resolved Within SLA / Total Tickets | ≥ 92% | Weekly |

### 6.4 Customer KPIs

| KPI | Definition | Target | Reporting Frequency |
|-----|-----------|--------|-------------------|
| Average Deposit Balance | Total Deposits / Active Deposit Accounts | Monitor trend | Monthly |
| Credit Card Utilization Rate | Balance / Credit Limit | Flag if > 80% | Monthly |
| Customer Lifetime Value (CLV) | Estimated revenue over customer relationship | Segment by tier | Quarterly |
| Product Holdings per Customer | Avg number of products per customer | ≥ 2.5 | Quarterly |
| High-Risk Customer % | Customers in risk tier 4–5 / Total | ≤ 8% | Monthly |

---

## 7. Scope Definition

### In Scope
- Retail banking KPIs across all 180+ branches
- Consumer loan portfolio (personal, auto, mortgage)
- Credit card portfolio
- Deposit accounts (checking, savings, CDs)
- Fraud transaction monitoring
- Branch operational metrics
- Customer segmentation by risk and value tier

### Out of Scope (for v1.0)
- Investment banking or wealth management products
- Real-time streaming (v2.0 roadmap item)
- Mobile app performance metrics
- Third-party vendor performance

---

## 8. Banking Scenarios — Realistic Business Context

These scenarios were modeled based on actual patterns discussed during stakeholder interviews and drive the design of the analytics layer:

### Scenario A — Delinquency Spike in Auto Loans
In Q3 2025, the risk team noticed auto loan delinquencies ticking up in the Southeast region. By the time the monthly report surfaced this, 3 additional cohorts had entered 30+ DPD status. The dashboard needs to surface this within the same week it starts trending.

### Scenario B — Branch Performance Divergence
Branch #47 (Nashville, TN) and Branch #112 (Houston, TX) have nearly identical headcount and market demographics but show a 31% gap in deposit growth. Leadership needs visibility into what's driving the gap — is it product mix, cross-sell rate, or operational throughput?

### Scenario C — Fraud Pattern in Digital Transactions
The fraud team identified in Feb 2026 that a cluster of accounts opened within the same 14-day window showed transaction velocity spikes within 90 days of account opening. This pattern wasn't caught until losses hit $2.1M. The dashboard should flag velocity anomalies within 72 hours.

### Scenario D — Credit Card Utilization Creep
High-utilization credit card accounts (>80% of limit) are 4.2x more likely to miss a payment within 90 days. Relationship managers need a filtered view of which customers in their book are approaching this threshold so they can proactively engage.

---

## 9. Expected Business Value

| Value Driver | Estimated Impact |
|-------------|-----------------|
| Faster fraud detection | Reduce fraud losses by 15–20% in year 1 |
| Proactive delinquency management | Reduce NPL ratio by 0.3–0.5 percentage points |
| Branch performance benchmarking | Identify underperformers — potential 8–12% improvement in branch revenue |
| Customer segmentation | Improve cross-sell conversion by targeting right tier — est. $4–6M additional revenue |
| Reporting efficiency | Eliminate ~120 hours/month of manual report compilation |
| Executive decision speed | Reduce decision lag from weekly cycle to daily |

---

## 10. Assumptions & Constraints

**Assumptions:**
- Data is sourced from 6 internal systems; this project uses synthetic data modeled on those schemas
- Daily data refresh is achievable via existing ETL pipelines
- Power BI Premium is available for deployment
- Branch-level granularity is available in source data

**Constraints:**
- PII must be masked in all non-production environments
- No real customer data used in this project (synthetic data only)
- Dashboard deployment is internal (not customer-facing)
- V1.0 limited to historical data; real-time streaming is a V2.0 feature

---

## 11. Project Timeline (High-Level)

| Phase | Description | Duration |
|-------|-------------|---------|
| Phase 1 | Business Understanding & Requirements | Week 1–2 |
| Phase 2 | Data Generation & Preparation | Week 2–3 |
| Phase 3 | SQL Analytics & Schema Design | Week 3–4 |
| Phase 4 | Python Analytics & Modeling | Week 4–6 |
| Phase 5 | Power BI Dashboard Development | Week 6–8 |
| Phase 6 | Documentation & Review | Week 8–9 |
| Phase 7 | GitHub Portfolio & Deployment | Week 9–10 |

---

## 12. Sign-Off

| Role | Name | Date |
|------|------|------|
| Project Sponsor (CFO) | Michael Hargrove | May 2026 |
| BI Lead | [Analyst Name] | May 2026 |
| CRO Representative | Sandra Voss | May 2026 |

---

*Document prepared by the Business Intelligence & Analytics Division, Apex Capital Bank. For internal use only.*
