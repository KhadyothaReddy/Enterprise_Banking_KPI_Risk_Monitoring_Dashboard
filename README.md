 Enterprise Banking KPI & Risk Monitoring Dashboard
Apex Capital Bank — Internal Analytics Initiative

![Status](https://img.shields.io/badge/Status-Complete-green)
![SQL](https://img.shields.io/badge/SQL-T--SQL-blue)
![Python](https://img.shields.io/badge/Python-3.10+-yellow)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-orange)
![Domain](https://img.shields.io/badge/Domain-Banking%20%26%20Finance-navy)

---

 What This Project Is

This is an end-to-end enterprise analytics solution I built to simulate the kind of work done inside a bank's business intelligence team. The scenario is realistic: **Apex Capital Bank** — a mid-sized commercial and retail bank — needed a consolidated view of financial performance, operational health, and risk exposure. Their leadership was working off fragmented Excel reports that were 3–4 days stale.

I designed and built the entire pipeline from scratch: data generation, SQL schema, Python analytics, Power BI dashboards, and documentation.

The goal was to answer the questions executives actually ask, not just build something that looks good in a screenshot.

---

 Business Problem

Apex Capital Bank's reporting was fragmented across six internal systems. The CFO, CRO, and Head of Retail Banking were working off Excel reports compiled manually — often arriving late, with inconsistent definitions for the same metrics. There was no early-warning system for fraud or delinquency trends.

**Specific pain points:**
- Reporting lag of 3–4 days before KPIs reached leadership
- No single agreed-upon definition for metrics like NPL ratio or NIM
- No fraud pattern detection — issues were found reactively
- No standardized branch benchmarking across 180+ locations
- ~120 hours/month wasted on manual Excel consolidation

---

 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Data Sources (Synthetic)                     │
│  CRM System │ Core Banking │ LOS │ Card Processing │ Fraud Engine│
└─────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Python Data Gen   │
                    │ generate_datasets  │
                    │     .py            │
                    └─────────┬─────────┘
                              │  7 CSV files (155K+ records)
                    ┌─────────▼─────────┐
                    │  SQL Data Mart     │
                    │  ACB_Analytics DB  │
                    │  Schema + ETL +    │
                    │  Stored Procs      │
                    └─────────┬─────────┘
                              │
             ┌────────────────┴──────────────────┐
             │                                   │
   ┌─────────▼─────────┐             ┌──────────▼──────────┐
   │  Python Analytics  │             │    Power BI Layer    │
   │  banking_analytics │             │   4 Dashboards       │
   │  .py               │             │   DAX Measures       │
   │  EDA, Fraud, Risk, │             │   Executive / Risk / │
   │  Segmentation,     │             │   Ops / Customer     │
   │  Forecasting       │             │                      │
   └───────────────────┘             └──────────────────────┘
```

---

 KPIs Tracked

 Financial
| KPI | Target |
|-----|--------|
| Net Interest Margin (NIM) | ≥ 3.2% |
| Loan-to-Deposit Ratio | 70–80% |
| Cost-to-Income Ratio | ≤ 58% |
| Revenue per Branch | Benchmark |

Risk
| KPI | Target |
|-----|--------|
| NPL Ratio | ≤ 1.8% |
| Delinquency Rate (30+ DPD) | ≤ 2.5% |
| Fraud Transaction Rate | ≤ 0.08% |
| High-Risk Customer % | ≤ 8% |

 Operations
| KPI | Target |
|-----|--------|
| Deposit Attainment | ≥ 100% |
| SLA Adherence | ≥ 92% |
| Digital Adoption Rate | ≥ 65% |
| CSAT Score | ≥ 4.0 / 5.0 |

---

What I Built

### Phase 1 — Business Understanding
Full project charter including stakeholder analysis, business problem definition, KPI framework, business rules, and realistic banking scenarios. This is the foundation that makes everything downstream defensible.

### Phase 2 — Data Generation
Seven synthetic datasets totaling 155,552 records. Built with realistic banking logic — income correlated to customer segment, credit scores tied to risk tier, fraud probability weighted by transaction type and amount, seasonal patterns in branch deposits, rate environment shifts post-2022 for loan interest rates.

### Phase 3 — SQL Analytics
- Schema design with proper indexing, foreign keys, and constraints
- Data cleaning queries (deduplication, null imputation, anomaly flagging)
- KPI analysis queries using CTEs, window functions, and ranking
- 4 stored procedures for scheduled reporting and drill-through queries

### Phase 4 — Python Analytics
- Data loading, deduplication, and imputation pipeline
- EDA charts: customer segments, income distribution, monthly transaction trends, loan portfolio
- Fraud trend analysis: loss by category, detection method precision, false positive rates
- Credit risk heatmap: delinquency by loan type and risk tier
- K-Means customer segmentation (K=4, silhouette score: 0.28)
- 6-month deposit volume forecast using linear regression
- Correlation matrix for customer financial attributes

### Phase 5 — Power BI
Complete DAX measure library (30+ measures) covering financial, risk, operational, and customer KPIs. Full data model relationship spec. Dashboard layout design for all 4 dashboards with slicer, drill-through, and conditional formatting logic.

### Phase 6 — Documentation
- Business Requirements Document (BRD) with stakeholder requirements and business rules
- Data Dictionary with definitions for all 7 tables, 60+ columns
- Executive Summary with data findings and 5 actionable business recommendations

---

## Key Findings

- Auto loans showing the highest delinquency rate by count — accelerating in Q1 2026 scenarios
- Card Not Present fraud is the highest-volume category; ML Model detection outperforms rules engine in precision
- K-Means identified 4 behavioral clusters — "High Risk / Low Engagement" (4,150 customers) needs targeted outreach
- Bottom quartile branches average 81% deposit attainment vs 107% top quartile — gap is not fully market-driven
- Digital adoption lags in South and Midwest — 58–61% vs 71% in West/Northeast

---

## Business Impact (Estimated)

| Impact Area | Estimated Value |
|-------------|----------------|
| Fraud loss reduction (ML expansion) | $189K–$252K/year |
| NPL improvement (early collections) | 0.3–0.5 pp NPL reduction |
| Branch performance lift (bottom quartile) | 8–12% deposit growth |
| Cross-sell revenue (segmentation targeting) | $4–6M additional revenue |
| Operational savings (reporting automation) | ~120 hrs/month eliminated |

---

## Tools & Technologies

| Tool | Use |
|------|-----|
| **Python** (pandas, numpy, matplotlib, scikit-learn) | Data generation, EDA, ML modeling, forecasting |
| **SQL** (T-SQL / SQL Server) | Schema design, KPI queries, stored procedures, data cleaning |
| **Power BI** | 4 executive dashboards, DAX measures, data model |
| **DAX** | 30+ KPI measures, time intelligence, conditional formatting logic |
| **Power Query** | Data transformation inside Power BI |
| **Excel / CSV** | Flat file data interchange format |

---

## Folder Structure

```
Enterprise_Banking_KPI_Risk_Monitoring_Dashboard/
│
├── Dataset/
│   ├── acb_customers.csv          (15,000 customers)
│   ├── acb_branches.csv           (80 branches)
│   ├── acb_transactions.csv       (120,000 transactions)
│   ├── acb_loans.csv              (8,000 loans)
│   ├── acb_credit_cards.csv       (10,000 accounts)
│   ├── acb_branch_performance.csv (1,920 monthly records)
│   └── acb_risk_fraud_flags.csv   (477 fraud flags)
│
├── SQL/
│   ├── 01_schema_design.sql       (7 tables, indexes, constraints)
│   ├── 02_data_cleaning.sql       (dedup, imputation, anomaly flags)
│   ├── 03_kpi_analysis.sql        (KPI queries, window functions, CTEs)
│   └── 04_stored_procedures.sql   (4 reusable reporting procedures)
│
├── Python/
│   ├── generate_datasets.py       (synthetic data generation)
│   └── banking_analytics.py       (EDA, fraud, risk, clustering, forecast)
│
├── PowerBI/
│   └── DAX_Measures.md            (30+ measures + dashboard layout specs)
│
├── Documentation/
│   ├── Phase1_Business_Understanding.md
│   ├── BRD_Business_Requirements.md
│   ├── Data_Dictionary.md
│   └── Executive_Summary_and_Recommendations.md
│
├── Images/                        (10 charts from Python analytics)
│
├── Reports/                       (6 CSV outputs from analytics pipeline)
│
└── README.md
```

---

## How to Run This Project

**Step 1 — Generate Datasets**
```bash
cd Python
python generate_datasets.py
```

**Step 2 — Run Python Analytics**
```bash
pip install pandas numpy matplotlib scikit-learn
python banking_analytics.py
```
All charts save to `/Images`, all reports save to `/Reports`.

**Step 3 — SQL Setup**
- Open SQL Server Management Studio (or Azure Data Studio)
- Run `01_schema_design.sql` → creates the ACB_Analytics database
- Import CSVs using SSMS Import Wizard or BULK INSERT
- Run `02_data_cleaning.sql` → cleans and validates the data
- Run `03_kpi_analysis.sql` → generates KPI query results
- Run `04_stored_procedures.sql` → creates reporting procedures

**Step 4 — Power BI**
- Open Power BI Desktop
- Get Data → Text/CSV → load all 7 CSVs from `/Dataset`
- Set up relationships per the spec in `DAX_Measures.md`
- Create a `_Measures` table and paste in all DAX measures
- Build dashboards per the layout specs

---

## Future Improvements (V2.0 Roadmap)

- Real-time streaming with Apache Kafka → Power BI
- Credit risk scoring model (XGBoost)
- Automated fraud alert emails via Power Automate
- Mobile app analytics integration
- Regulatory reporting automation (Call Report)

---

## About This Project

This project was built as part of a business analytics portfolio to demonstrate end-to-end analytics skills across the full stack: requirements gathering, data engineering, SQL analytics, Python modeling, and BI development.

All data is synthetic and generated for analytical purposes. No real customer data was used.

---

*Built by: Khadyothamani Atla | Business Analytics Graduate Student*  

