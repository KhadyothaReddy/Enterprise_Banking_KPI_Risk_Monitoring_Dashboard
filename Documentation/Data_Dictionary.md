# Data Dictionary
## Apex Capital Bank — Enterprise Analytics Data Mart
**Document ID:** ACB-BI-DD-2025-09  
**Version:** 1.3  
**Author:** Data Engineering & BI Team  
**Date:** September 2025 (Updated May 2026)

> This document defines every table, column, data type, and business rule in the ACB analytics data mart. Any analyst using this data for reporting must reference this document to ensure consistent metric definitions.

---

## TABLE: acb_customers

**Description:** Customer master table. One row per unique customer account.  
**Source:** CRM System (Salesforce) + Core Banking Extract  
**Refresh:** Daily at 06:00 EST  
**Row Count (approx):** 15,000

| Column | Data Type | Nullable | Description | Example | Business Rule |
|--------|-----------|----------|-------------|---------|---------------|
| customer_id | VARCHAR(15) | NO | Unique customer identifier. Format: ACB-C###### | ACB-C000001 | Primary Key |
| first_name | VARCHAR(50) | YES | Customer first name. Masked in non-prod environments | James | PII — masked |
| last_name | VARCHAR(50) | YES | Customer last name. Masked in non-prod environments | Johnson | PII — masked |
| age | TINYINT | YES | Customer age at time of last record update | 42 | Range: 18–100 |
| state | CHAR(2) | NO | US state abbreviation of primary address | TX | Must be valid US state code |
| region | VARCHAR(20) | NO | Geographic region grouping | South | Derived from state |
| occupation | VARCHAR(50) | YES | Employment category | Employed - Full Time | NULL → 'Unknown' |
| annual_income | DECIMAL(14,2) | YES | Gross annual income in USD | 72450.00 | NULL → imputed from segment median |
| credit_score | SMALLINT | YES | FICO credit score | 720 | Range: 300–850. NULL → imputed |
| customer_segment | VARCHAR(25) | NO | Business-defined segment | Emerging Affluent | 4 valid values: Mass Market, Emerging Affluent, Affluent, High Net Worth |
| risk_tier | TINYINT | NO | Internal risk classification (1=lowest, 5=highest) | 2 | Range: 1–5 |
| account_open_date | DATE | NO | Date customer first opened an account with ACB | 2019-03-15 | Cannot be future date |
| is_digital_customer | BIT | NO | 1 if customer primarily uses digital channels | 1 | 1=Digital, 0=Branch-first |
| num_products | TINYINT | NO | Number of distinct product types held (deposits, loans, cards, etc.) | 3 | Range: 1–5 |
| is_active | BIT | NO | 1 if account is currently active | 1 | 0 = closed/dormant |

---

## TABLE: acb_branches

**Description:** Branch master — static attributes per branch location.  
**Source:** Branch Operations System  
**Refresh:** Monthly (or on change)  
**Row Count (approx):** 80

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| branch_id | VARCHAR(12) | NO | Unique branch ID. Format: ACB-BR### | ACB-BR001 |
| branch_name | VARCHAR(100) | NO | Human-readable branch name | ACB Houston - ACB-BR001 |
| city | VARCHAR(50) | NO | Branch city | Houston |
| state | CHAR(2) | NO | Branch state | TX |
| region | VARCHAR(20) | NO | Geographic region | South |
| branch_type | VARCHAR(20) | NO | Operational type | Full Service |
| num_employees | SMALLINT | NO | Current headcount at branch | 24 |
| open_year | SMALLINT | NO | Year branch opened | 2004 |
| monthly_deposit_target | DECIMAL(18,2) | NO | Monthly deposit target in USD | 28500000.00 |
| is_active | BIT | NO | 1 if branch is currently open | 1 |

**Branch Type Definitions:**
- **Full Service**: Full banking services including loans, deposits, safe deposit boxes
- **Drive-Through**: Limited transactions, no loan officers
- **In-Store**: Located inside retail store, limited service hours
- **Corporate**: Handles large commercial and business banking clients

---

## TABLE: acb_transactions

**Description:** Individual transaction records. High-volume operational table.  
**Source:** Core Banking Transaction System  
**Refresh:** Daily  
**Row Count (approx):** 120,000+

| Column | Data Type | Nullable | Description | Example | Business Rule |
|--------|-----------|----------|-------------|---------|---------------|
| transaction_id | VARCHAR(18) | NO | Unique transaction ID. Format: ACB-TXN######## | ACB-TXN00000001 | PK |
| customer_id | VARCHAR(15) | NO | Customer who initiated transaction | ACB-C000001 | FK → customers |
| branch_id | VARCHAR(12) | YES | Branch where transaction occurred. NULL = digital-only | ACB-BR001 | FK → branches |
| transaction_date | DATE | NO | Date of transaction | 2025-11-15 | — |
| transaction_type | VARCHAR(25) | NO | Type of transaction | Deposit | See valid values below |
| channel | VARCHAR(20) | YES | Channel through which transaction occurred | Mobile App | NULL → 'Unknown Channel' |
| amount | DECIMAL(18,2) | NO | Transaction amount in USD | 2500.00 | Must be > 0 |
| status | VARCHAR(15) | NO | Processing status | Completed | Completed / Pending / Reversed / Failed |
| is_fraud_flag | BIT | NO | 1 if transaction was flagged by fraud rules engine | 0 | — |
| currency | CHAR(3) | NO | Currency code | USD | USD only (V1) |

**Transaction Type Valid Values:**
Deposit, Withdrawal, Transfer, Bill Payment, POS Purchase, ATM Withdrawal, Wire Transfer, Direct Deposit

**Channel Valid Values:**
Branch, ATM, Mobile App, Online Banking, Telephone, Unknown Channel

---

## TABLE: acb_loans

**Description:** Loan portfolio. One row per loan account.  
**Source:** Loan Origination System (LOS)  
**Refresh:** Daily  
**Row Count (approx):** 8,000

| Column | Data Type | Nullable | Description | Example | Business Rule |
|--------|-----------|----------|-------------|---------|---------------|
| loan_id | VARCHAR(15) | NO | Unique loan ID. Format: ACB-LN####### | ACB-LN0000001 | PK |
| customer_id | VARCHAR(15) | NO | Borrower customer ID | ACB-C000042 | FK → customers |
| loan_type | VARCHAR(25) | NO | Category of loan | Mortgage | See valid values |
| origination_date | DATE | NO | Date loan was disbursed | 2022-07-15 | — |
| loan_amount | DECIMAL(18,2) | NO | Original principal amount | 285000.00 | Must be > 0 |
| outstanding_balance | DECIMAL(18,2) | NO | Remaining balance as of last update | 242000.00 | Must be ≥ 0 |
| interest_rate | DECIMAL(6,4) | YES | Annual interest rate as decimal | 0.0725 | 7.25% rate. NULL → imputed from type avg |
| term_months | SMALLINT | YES | Original loan term in months | 360 | 360 = 30-year mortgage |
| loan_status | VARCHAR(20) | NO | Current performance status | Current | See status definitions |
| days_past_due | SMALLINT | NO | Calendar days past due date | 0 | 0 = current |
| is_npl | BIT | NO | 1 if loan qualifies as Non-Performing | 0 | NPL = 90+ DPD OR Default OR Written Off |
| branch_originated | VARCHAR(12) | YES | Branch that originated the loan | ACB-BR015 | FK → branches |

**Loan Type Valid Values:**
Personal Loan, Auto Loan, Mortgage, Home Equity Loan, Student Loan, Small Business Loan

**Loan Status Definitions:**
- **Current**: 0 days past due, payments on track
- **30-59 DPD**: 30 to 59 calendar days past due
- **60-89 DPD**: 60 to 89 calendar days past due
- **90+ DPD**: 90 or more days past due — qualifies as NPL
- **Default**: Formally defaulted — qualifies as NPL
- **Paid Off**: Loan fully repaid — excluded from active portfolio
- **Written Off**: Charged off as uncollectable — counts as NPL for historical reporting

---

## TABLE: acb_credit_cards

**Description:** Credit card account table. One row per card account.  
**Source:** Card Processing System  
**Refresh:** Daily  
**Row Count (approx):** 10,000

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| card_id | VARCHAR(15) | NO | Unique card account ID | ACB-CC0000001 |
| customer_id | VARCHAR(15) | NO | Card holder customer ID | ACB-C000088 |
| card_type | VARCHAR(15) | NO | Card product type | Rewards |
| credit_limit | DECIMAL(12,2) | NO | Approved credit limit | 12000.00 |
| current_balance | DECIMAL(12,2) | NO | Balance as of last statement | 4800.00 |
| utilization_rate | DECIMAL(5,4) | YES | Balance / Limit ratio | 0.4000 |
| open_date | DATE | NO | Date card account was opened | 2021-04-01 |
| payment_status | VARCHAR(15) | NO | Payment performance | Current |
| reward_points | INT | NO | Accumulated reward points | 24500 |
| is_active | BIT | NO | 1 if card is active | 1 |
| annual_fee | DECIMAL(8,2) | NO | Annual fee charged for card | 95.00 |

**Utilization Alert Threshold:** utilization_rate > 0.80 triggers proactive outreach flag  
**Card Types:** Standard (no fee), Rewards ($95), Platinum ($195), Business ($150), Secured ($35)

---

## TABLE: acb_branch_performance

**Description:** Monthly aggregated branch KPIs. One row per branch per month.  
**Source:** Calculated from branch_operations + finance system extract  
**Refresh:** Monthly (1st business day of following month)  
**Row Count (approx):** 80 branches × 24 months = 1,920

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| branch_id | VARCHAR(12) | NO | Branch identifier | ACB-BR047 |
| report_month | CHAR(7) | NO | Reporting month in YYYY-MM format | 2025-11 |
| actual_deposits | DECIMAL(18,2) | NO | Total deposits received at branch that month | 31250000.00 |
| deposit_target | DECIMAL(18,2) | NO | Monthly deposit goal for that branch | 28500000.00 |
| deposit_attainment | DECIMAL(6,4) | NO | actual_deposits / deposit_target | 1.0965 |
| new_accounts_opened | SMALLINT | NO | New customer accounts opened | 32 |
| loan_originations | SMALLINT | NO | New loans originated at branch | 28 |
| operating_expenses | DECIMAL(18,2) | NO | Total branch operating costs | 145000.00 |
| num_employees | SMALLINT | NO | Headcount at end of month | 24 |
| revenue_per_employee | DECIMAL(14,2) | YES | Estimated revenue / headcount | 41667.00 |
| csat_score | DECIMAL(3,1) | YES | Customer satisfaction (1–5 scale) | 4.2 |
| sla_adherence_rate | DECIMAL(5,4) | YES | % of service requests resolved within SLA | 0.9412 |

---

## TABLE: acb_risk_fraud_flags

**Description:** Fraud investigation records linked to flagged transactions.  
**Source:** Fraud Rules Engine + ML Model Outputs  
**Refresh:** Daily  
**Row Count (approx):** 477 (grows continuously)

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| flag_id | VARCHAR(15) | NO | Unique flag record ID | ACB-RF0000001 |
| transaction_id | VARCHAR(18) | NO | Flagged transaction | ACB-TXN00004521 |
| customer_id | VARCHAR(15) | NO | Customer associated with flag | ACB-C000213 |
| flag_date | DATE | NO | Date flag was raised | 2025-11-01 |
| flag_category | VARCHAR(35) | NO | Fraud type classification | Card Not Present |
| flagged_amount | DECIMAL(18,2) | NO | Amount of the flagged transaction | 8750.00 |
| investigation_status | VARCHAR(20) | NO | Current investigation state | Confirmed Fraud |
| loss_amount | DECIMAL(18,2) | NO | Confirmed financial loss (0 if not yet confirmed) | 7200.00 |
| detection_method | VARCHAR(20) | NO | How the flag was raised | ML Model |

**Flag Categories:** Account Takeover, Card Not Present, Identity Theft, Synthetic Identity, Transaction Velocity, Unusual Geography, Money Laundering Suspicion, Structuring

**Detection Methods:** Rules Engine, ML Model, Manual Review, Customer Report

---

## KPI CALCULATION REFERENCE

| KPI | Numerator | Denominator | Notes |
|-----|-----------|-------------|-------|
| NPL Ratio | Outstanding balance where is_npl=1 | Total outstanding balance (excl. Paid Off) | Target ≤1.8% |
| Delinquency Rate | Loans with DPD ≥30 | All active loans | Target ≤2.5% |
| Deposit Attainment | actual_deposits | deposit_target | Target ≥100% |
| Fraud Transaction Rate | Transactions with is_fraud_flag=1 | All completed transactions | Target ≤0.08% |
| Digital Adoption | Txns via Mobile App or Online Banking | All completed transactions | Target ≥65% |
| SLA Adherence | Tickets resolved within SLA | All tickets | Target ≥92% |
| NIM Proxy | Sum(outstanding_balance × interest_rate) | Sum(loan balance + deposits) | Target ≥3.2% |

---

*Data Dictionary maintained by the Business Intelligence & Data Engineering Division, Apex Capital Bank.*  
*Version changes tracked in: /Documentation/changelog.md*
