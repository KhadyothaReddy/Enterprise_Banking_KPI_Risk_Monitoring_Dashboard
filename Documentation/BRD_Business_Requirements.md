# Business Requirements Document (BRD)
## Apex Capital Bank — Enterprise KPI & Risk Monitoring Dashboard
**Document ID:** ACB-BI-BRD-2025-07  
**Version:** 2.1  
**Status:** Approved  
**Author:** Senior Business Analyst, BI & Analytics Division  
**Reviewers:** CFO Office, CRO, Head of Retail Banking, VP Operations  
**Date:** November 2025 (Updated May 2026)

---

## 1. Executive Summary

Apex Capital Bank's current reporting infrastructure relies on fragmented Excel-based reports compiled manually across six source systems. This results in 3–4 day reporting lags, inconsistent KPI definitions across teams, and no early-warning capability for emerging risk trends.

This document defines the business requirements for an Enterprise KPI & Risk Monitoring Dashboard — a centralized analytics solution built on Power BI with underlying SQL and Python analytics pipelines. The objective is to provide leadership with a single, trusted, daily-refreshed view of the bank's financial performance, operational health, customer behavior, and risk exposure.

---

## 2. Business Problem

| Problem | Business Impact |
|---------|----------------|
| Reporting lags of 3–4 days | Decisions made on stale data; risk issues not caught early |
| No centralized KPI definition | Same metric calculated differently by different teams |
| No fraud early-warning system | Fraud losses escalating before detection |
| Branch performance opacity | No standardized comparison across 180+ branches |
| Manual report compilation | ~120 hours/month wasted on Excel consolidation |

---

## 3. Business Objectives

**Primary Objectives:**
1. Build a single, consolidated dashboard environment for all banking KPIs
2. Reduce reporting cycle from 3–4 days to daily automated refresh
3. Create an early-warning risk and fraud monitoring layer
4. Enable branch performance benchmarking at regional and state level
5. Establish a formally documented, agreed-upon KPI framework

**Success Criteria:**
- Dashboard live and in use by ≥80% of target executives within 60 days of deployment
- Reporting lag reduced to T+1 (data from yesterday, available today)
- Fraud detection time reduced from avg 14 days to ≤5 days post-incident
- Manual Excel reporting eliminated for the 6 KPI categories in scope

---

## 4. Stakeholder Requirements (Gathered via Interviews)

### 4.1 CFO — Michael Hargrove
- "I need one number for NIM that everyone agrees on. Right now finance and risk give me different numbers."
- Wants: Monthly NIM trend, Cost-to-Income by region, LDR with traffic light status
- Format: Executive summary view, printable 1-page snapshot

### 4.2 Chief Risk Officer — Sandra Voss
- "I hear about delinquency spikes from regulators before I hear from my own team."
- Wants: Weekly delinquency view by product and geography, fraud trend alerts, high-risk customer concentration
- Format: Risk monitoring dashboard with drill-through to individual loan/customer level

### 4.3 Head of Retail Banking — David Chen
- "Branch 47 and Branch 112 look the same on paper. I need to understand why their results are so different."
- Wants: Branch attainment ranking, new account trends, cross-sell rates, deposit targets vs actuals
- Format: Operational dashboard, sortable branch table, regional filters

### 4.4 VP Operations — Renata Okafor
- "We're spending more per employee than our peers and I can't prove or disprove that with the data I have."
- Wants: Revenue per employee, SLA adherence, digital adoption trend, headcount efficiency
- Format: Operational KPIs, benchmark view, trend lines

---

## 5. Business Rules

| Rule | Description |
|------|-------------|
| BR-001 | NPL definition: all loans 90+ DPD + Default status + Written Off |
| BR-002 | Delinquency rate: loans 30+ DPD as % of total active loans |
| BR-003 | Active loan: any loan not in Paid Off status |
| BR-004 | Deposit target attainment: actual deposits / monthly branch target |
| BR-005 | Digital transaction: channel = Mobile App or Online Banking |
| BR-006 | High-risk customer: risk_tier ≥ 4 |
| BR-007 | Fraud transaction rate: is_fraud_flag=1 / total completed transactions |
| BR-008 | NIM proxy: avg loan interest income / avg earning assets (loans + deposits) |
| BR-009 | Cost-to-Income: total operating expenses / estimated net interest income |
| BR-010 | High credit card utilization: utilization_rate > 80% |

---

## 6. Assumptions

1. Source data is refreshed daily via existing ETL pipelines by 6:00 AM EST
2. Power BI Premium is provisioned for scheduled refresh
3. All customer PII is masked in the analytics environment
4. Branch targets are set quarterly and stored in branch_performance table
5. Currency is USD throughout; multi-currency not in scope for V1

---

## 7. Constraints

1. No real customer PII may be used in non-production environments
2. Dashboard is internal-facing only (not customer-facing)
3. Real-time streaming is out of scope for V1.0
4. Investment banking and wealth management excluded from V1

---

## 8. Out of Scope

- Real-time transaction monitoring
- Customer-facing portals
- Mobile app analytics
- Third-party credit bureau integrations
- Automated alerts/notifications (flagged as V2.0 feature)

---

## 9. Approvals

| Role | Name | Date | Signature |
|------|------|------|-----------|
| CFO | Michael Hargrove | Nov 2025 | ✓ Approved |
| CRO | Sandra Voss | Nov 2025 | ✓ Approved |
| Head of Retail | David Chen | Nov 2025 | ✓ Approved |
| BI Lead | [Analyst] | Nov 2025 | ✓ Approved |

---

*ACB Internal Document — Confidential. Not for external distribution.*
