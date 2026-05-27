# Power BI DAX Measures — Apex Capital Bank
## Enterprise KPI & Risk Monitoring Dashboard
**File:** DAX_Measures.md  
**Author:** BI Development Team  
**Version:** 1.2  
**Date:** May 2026

---

## HOW TO USE THIS FILE

1. Open Power BI Desktop
2. Load all 7 CSVs from the `/Dataset` folder
3. Set up relationships (see Section 0)
4. Create a new **Measure Table** (blank table named `_Measures`)
5. Copy each DAX measure below into that table

All measures go in `_Measures` unless noted otherwise.

---

## SECTION 0 — DATA MODEL RELATIONSHIPS

Set these up in Model View before creating measures:

| From Table | From Column | To Table | To Column | Cardinality |
|-----------|-------------|----------|-----------|-------------|
| acb_transactions | customer_id | acb_customers | customer_id | Many-to-One |
| acb_transactions | branch_id | acb_branches | branch_id | Many-to-One |
| acb_loans | customer_id | acb_customers | customer_id | Many-to-One |
| acb_loans | branch_originated | acb_branches | branch_id | Many-to-One |
| acb_credit_cards | customer_id | acb_customers | customer_id | Many-to-One |
| acb_branch_performance | branch_id | acb_branches | branch_id | Many-to-One |
| acb_risk_fraud_flags | customer_id | acb_customers | customer_id | Many-to-One |
| acb_risk_fraud_flags | transaction_id | acb_transactions | transaction_id | Many-to-One |

**Cross-filter direction:** Single (default) for all relationships.

---

## SECTION 1 — FINANCIAL KPI MEASURES

```dax
// ── Total Deposits ─────────────────────────────────────────────
Total Deposits = 
CALCULATE(
    SUM(acb_transactions[amount]),
    acb_transactions[transaction_type] IN {"Deposit", "Direct Deposit"},
    acb_transactions[status] = "Completed"
)

// ── Total Withdrawals ──────────────────────────────────────────
Total Withdrawals = 
CALCULATE(
    SUM(acb_transactions[amount]),
    acb_transactions[transaction_type] IN {"Withdrawal", "ATM Withdrawal"},
    acb_transactions[status] = "Completed"
)

// ── Net Cash Flow ──────────────────────────────────────────────
Net Cash Flow = [Total Deposits] - [Total Withdrawals]

// ── Total Loan Portfolio (Outstanding) ────────────────────────
Total Loan Balance = 
CALCULATE(
    SUM(acb_loans[outstanding_balance]),
    NOT acb_loans[loan_status] IN {"Paid Off"}
)

// ── Loan-to-Deposit Ratio ──────────────────────────────────────
// Target: 70-80%. This should be monitored monthly.
Loan-to-Deposit Ratio = 
DIVIDE([Total Loan Balance], [Total Deposits], 0)

LDR % = 
FORMAT([Loan-to-Deposit Ratio], "0.0%")

// ── Estimated Net Interest Margin (NIM) ───────────────────────
// Proxy: Average loan interest income / average earning assets
// In a real environment this would pull from the GL
Estimated NIM = 
VAR TotalInterestIncome = 
    SUMX(
        FILTER(acb_loans, NOT acb_loans[loan_status] IN {"Paid Off"}),
        acb_loans[outstanding_balance] * acb_loans[interest_rate]
    )
VAR TotalEarningAssets = [Total Loan Balance] + [Total Deposits]
RETURN
DIVIDE(TotalInterestIncome, TotalEarningAssets, 0)

Estimated NIM % = FORMAT([Estimated NIM], "0.00%")

// ── Cost-to-Income Ratio ───────────────────────────────────────
Total Operating Expenses = SUM(acb_branch_performance[operating_expenses])

Estimated Revenue = 
SUMX(
    acb_branch_performance,
    acb_branch_performance[actual_deposits] * 0.032
)

Cost-to-Income Ratio = 
DIVIDE([Total Operating Expenses], [Estimated Revenue], 0)

Cost-to-Income % = FORMAT([Cost-to-Income Ratio], "0.0%")

// ── Revenue per Branch ────────────────────────────────────────
Revenue per Branch = 
DIVIDE([Estimated Revenue], DISTINCTCOUNT(acb_branches[branch_id]), 0)

// ── Revenue per Employee ─────────────────────────────────────
Revenue per Employee = 
DIVIDE([Estimated Revenue], SUM(acb_branch_performance[num_employees]), 0)
```

---

## SECTION 2 — RISK KPI MEASURES

```dax
// ── Total NPL Balance ─────────────────────────────────────────
Total NPL Balance = 
CALCULATE(
    SUM(acb_loans[outstanding_balance]),
    acb_loans[is_npl] = 1
)

// ── NPL Ratio ─────────────────────────────────────────────────
// Regulatory target: ≤ 1.8%
// Red flag if consistently above 2%
NPL Ratio = 
DIVIDE([Total NPL Balance], [Total Loan Balance], 0)

NPL Ratio % = FORMAT([NPL Ratio], "0.00%")

NPL Status = 
SWITCH(
    TRUE(),
    [NPL Ratio] <= 0.018, "✅ Within Target",
    [NPL Ratio] <= 0.025, "⚠️ Approaching Limit",
    "🔴 Exceeds Threshold"
)

// ── Delinquency Rate (30+ DPD) ───────────────────────────────
Delinquent Loans Count = 
CALCULATE(
    COUNTROWS(acb_loans),
    acb_loans[days_past_due] >= 30,
    NOT acb_loans[loan_status] = "Paid Off"
)

Total Active Loans = 
CALCULATE(
    COUNTROWS(acb_loans),
    NOT acb_loans[loan_status] IN {"Paid Off"}
)

Delinquency Rate = 
DIVIDE([Delinquent Loans Count], [Total Active Loans], 0)

Delinquency Rate % = FORMAT([Delinquency Rate], "0.00%")

// ── Fraud KPIs ────────────────────────────────────────────────
Total Fraud Flags = 
CALCULATE(
    COUNTROWS(acb_risk_fraud_flags)
)

Confirmed Fraud Cases = 
CALCULATE(
    COUNTROWS(acb_risk_fraud_flags),
    acb_risk_fraud_flags[investigation_status] = "Confirmed Fraud"
)

Total Fraud Loss = 
SUM(acb_risk_fraud_flags[loss_amount])

Fraud Detection Precision = 
DIVIDE([Confirmed Fraud Cases], [Total Fraud Flags], 0)

Fraud Detection Precision % = FORMAT([Fraud Detection Precision], "0.0%")

False Positive Rate = 
DIVIDE(
    CALCULATE(
        COUNTROWS(acb_risk_fraud_flags),
        acb_risk_fraud_flags[investigation_status] = "False Positive"
    ),
    [Total Fraud Flags],
    0
)

// ── Fraud Transaction Rate ────────────────────────────────────
// Target: ≤ 0.08% of all completed transactions
Fraud Transaction Rate = 
DIVIDE(
    CALCULATE(
        COUNTROWS(acb_transactions),
        acb_transactions[is_fraud_flag] = 1
    ),
    CALCULATE(
        COUNTROWS(acb_transactions),
        acb_transactions[status] = "Completed"
    ),
    0
)

// ── High-Risk Customer % ──────────────────────────────────────
High Risk Customers = 
CALCULATE(
    COUNTROWS(acb_customers),
    acb_customers[risk_tier] >= 4,
    acb_customers[is_active] = 1
)

Total Active Customers = 
CALCULATE(
    COUNTROWS(acb_customers),
    acb_customers[is_active] = 1
)

High Risk Customer % = 
DIVIDE([High Risk Customers], [Total Active Customers], 0)
```

---

## SECTION 3 — OPERATIONAL KPI MEASURES

```dax
// ── Deposit Attainment ────────────────────────────────────────
Total Actual Deposits (Branch) = SUM(acb_branch_performance[actual_deposits])
Total Deposit Target = SUM(acb_branch_performance[deposit_target])

Overall Deposit Attainment = 
DIVIDE([Total Actual Deposits (Branch)], [Total Deposit Target], 0)

Deposit Attainment % = FORMAT([Overall Deposit Attainment], "0.0%")

// ── New Accounts ──────────────────────────────────────────────
Total New Accounts = SUM(acb_branch_performance[new_accounts_opened])

// ── Loan Originations ─────────────────────────────────────────
Total Loan Originations = SUM(acb_branch_performance[loan_originations])

// ── CSAT Score ────────────────────────────────────────────────
Average CSAT = AVERAGE(acb_branch_performance[csat_score])

CSAT Status = 
SWITCH(
    TRUE(),
    [Average CSAT] >= 4.3, "✅ Excellent",
    [Average CSAT] >= 3.8, "👍 Good",
    [Average CSAT] >= 3.0, "⚠️ Needs Improvement",
    "🔴 Critical"
)

// ── SLA Adherence ────────────────────────────────────────────
Average SLA Adherence = AVERAGE(acb_branch_performance[sla_adherence_rate])

SLA Adherence % = FORMAT([Average SLA Adherence], "0.0%")

// ── Digital Adoption Rate ─────────────────────────────────────
Total Digital Transactions = 
CALCULATE(
    COUNTROWS(acb_transactions),
    acb_transactions[channel] IN {"Mobile App", "Online Banking"},
    acb_transactions[status] = "Completed"
)

Total Completed Transactions = 
CALCULATE(
    COUNTROWS(acb_transactions),
    acb_transactions[status] = "Completed"
)

Digital Adoption Rate = 
DIVIDE([Total Digital Transactions], [Total Completed Transactions], 0)

Digital Adoption % = FORMAT([Digital Adoption Rate], "0.0%")
```

---

## SECTION 4 — CUSTOMER KPI MEASURES

```dax
// ── Average Credit Score ─────────────────────────────────────
Avg Credit Score = 
AVERAGE(acb_customers[credit_score])

// ── Average Products per Customer ────────────────────────────
Avg Products per Customer = 
AVERAGE(acb_customers[num_products])

// ── High Utilization Credit Cards ────────────────────────────
High Util Cards = 
CALCULATE(
    COUNTROWS(acb_credit_cards),
    acb_credit_cards[utilization_rate] > 0.80,
    acb_credit_cards[is_active] = 1
)

Total Active Cards = 
CALCULATE(
    COUNTROWS(acb_credit_cards),
    acb_credit_cards[is_active] = 1
)

High Utilization Rate = 
DIVIDE([High Util Cards], [Total Active Cards], 0)

// ── Average Credit Limit ─────────────────────────────────────
Avg Credit Limit = 
CALCULATE(
    AVERAGE(acb_credit_cards[credit_limit]),
    acb_credit_cards[is_active] = 1
)

// ── Average CC Balance ────────────────────────────────────────
Avg CC Balance = 
CALCULATE(
    AVERAGE(acb_credit_cards[current_balance]),
    acb_credit_cards[is_active] = 1
)
```

---

## SECTION 5 — TIME INTELLIGENCE MEASURES

```dax
// ── For time intelligence, create a Date Table first ─────────
// In Power BI: Modeling > New Table > paste this:
//
// DateTable = CALENDAR(DATE(2023,1,1), DATE(2026,12,31))
//
// Then add columns:
// Year = YEAR(DateTable[Date])
// Month = MONTH(DateTable[Date])
// MonthName = FORMAT(DateTable[Date], "MMM")
// Quarter = "Q" & QUARTER(DateTable[Date])
// YearMonth = FORMAT(DateTable[Date], "YYYY-MM")
//
// Mark it as a Date Table (right-click > Mark as date table)
// Connect acb_transactions[transaction_date] to DateTable[Date]

// ── MoM Deposit Growth ────────────────────────────────────────
Total Deposits MoM = 
VAR CurrentMonthDeposits = [Total Deposits]
VAR PriorMonthDeposits = 
    CALCULATE(
        [Total Deposits],
        DATEADD(DateTable[Date], -1, MONTH)
    )
RETURN
DIVIDE(CurrentMonthDeposits - PriorMonthDeposits, PriorMonthDeposits, 0)

MoM Deposit Growth % = FORMAT([Total Deposits MoM], "+0.0%;-0.0%;0.0%")

// ── YTD Deposits ──────────────────────────────────────────────
YTD Deposits = 
CALCULATE(
    [Total Deposits],
    DATESYTD(DateTable[Date])
)

// ── Prior Year Deposits ───────────────────────────────────────
PY Deposits = 
CALCULATE(
    [Total Deposits],
    SAMEPERIODLASTYEAR(DateTable[Date])
)

YoY Deposit Growth = 
DIVIDE([Total Deposits] - [PY Deposits], [PY Deposits], 0)

// ── Rolling 3-Month Average (Deposits) ────────────────────────
Rolling 3M Avg Deposits = 
CALCULATE(
    AVERAGEX(
        DATESINPERIOD(DateTable[Date], LASTDATE(DateTable[Date]), -3, MONTH),
        [Total Deposits]
    )
)

// ── YTD Fraud Loss ────────────────────────────────────────────
YTD Fraud Loss = 
CALCULATE(
    [Total Fraud Loss],
    DATESYTD(DateTable[Date])
)
```

---

## SECTION 6 — KPI CARD COLOR LOGIC (Conditional Formatting)

Use these in KPI card background color rules:

```dax
// NPL Ratio Color
NPL Color = 
SWITCH(
    TRUE(),
    [NPL Ratio] <= 0.018, "#1E8449",   -- Green
    [NPL Ratio] <= 0.025, "#D4A017",   -- Amber
    "#C0392B"                           -- Red
)

// Deposit Attainment Color
Attainment Color = 
SWITCH(
    TRUE(),
    [Overall Deposit Attainment] >= 1.05, "#1E8449",
    [Overall Deposit Attainment] >= 0.90, "#D4A017",
    "#C0392B"
)

// CSAT Color
CSAT Color = 
SWITCH(
    TRUE(),
    [Average CSAT] >= 4.3, "#1E8449",
    [Average CSAT] >= 3.8, "#D4A017",
    "#C0392B"
)
```

---

## SECTION 7 — DASHBOARD LAYOUT GUIDE

### Dashboard 1 — Executive Summary
```
Row 1 (KPI Cards):
  [Total Deposits] | [Total Loan Balance] | [NPL Ratio %] | [Fraud Loss $] | [CSAT Score]

Row 2:
  Left (60%): Monthly Deposits vs Target — Line + Bar combo
  Right (40%): Loan Portfolio by Type — Donut chart

Row 3:
  Left (50%): Deposit Attainment by Region — Bar chart
  Right (50%): Risk Tier Distribution — Stacked bar

Slicers: Region | State | Date Range | Customer Segment
```

### Dashboard 2 — Risk Monitoring
```
Row 1 (KPI Cards):
  [NPL Ratio] | [Delinquency Rate] | [Fraud Flags (30d)] | [Fraud Loss YTD] | [High Risk Customer %]

Row 2:
  Left: Delinquency Rate by Loan Type — Heatmap matrix visual
  Right: Fraud Loss by Category — Horizontal bar

Row 3:
  Full Width: Monthly Fraud Trend — Area chart with flag type breakdown

Row 4:
  Left: Geographic Risk Map (State level NPL %) — Filled map
  Right: High Utilization CC by Segment — Bar

Drill-through: Click any bar → Customer-level detail page
Slicers: Date | Loan Type | Risk Tier | Region
```

### Dashboard 3 — Branch Operations
```
Row 1 (KPI Cards):
  [Total New Accounts] | [Loan Originations] | [Avg CSAT] | [SLA Adherence %] | [Digital Adoption %]

Row 2:
  Full Width: Branch Attainment Ranking Table
    Columns: Branch | City | State | Type | Attainment % | CSAT | SLA | Rev/Employee
    Conditional formatting on Attainment column

Row 3:
  Left: Monthly New Accounts Trend — Line chart by region
  Right: Operating Expenses vs Revenue — Grouped bar by branch type

Slicers: Region | Branch Type | Month | State
Drill-through: Branch → Monthly trend page
```

### Dashboard 4 — Customer Insights
```
Row 1 (KPI Cards):
  [Total Customers] | [Avg Credit Score] | [Avg Products/Customer] | [High Util CC %] | [Digital Adoption %]

Row 2:
  Left: Customer Segment Distribution — Donut
  Right: Income vs Credit Score — Scatter plot (sample 2k customers)

Row 3:
  Left: K-Means Cluster Summary — Matrix visual
  Right: Credit Card Utilization Distribution — Histogram

Drill-through: Customer Segment → Risk profile detail page
Slicers: Segment | Risk Tier | Region | Digital Customer (Y/N)
```

---

*End of DAX Measures & Dashboard Specification*  
*Power BI file: ACB_KPI_Risk_Dashboard.pbix (build from this spec)*
