-- ============================================================
-- Apex Capital Bank — KPI Analysis Queries
-- File: 03_kpi_analysis.sql
-- Author: BI & Analytics Team
-- Created: May 2026
--
-- Purpose:
--   Core KPI queries that power the executive dashboard.
--   These queries are the "business logic" layer — they translate
--   raw data into the metrics leadership actually makes decisions on.
--
-- Structure:
--   Section 1 — Financial KPIs
--   Section 2 — Risk KPIs
--   Section 3 — Operational KPIs
--   Section 4 — Customer KPIs
--   Section 5 — Trend Queries (Window Functions)
--   Section 6 — Geographic Breakdown
-- ============================================================

USE ACB_Analytics;
GO


-- ============================================================
-- SECTION 1 — FINANCIAL KPIs
-- ============================================================

-- 1a. Loan-to-Deposit Ratio (LDR) by Month
--     LDR = Total Outstanding Loans / Total Deposits
--     Target: 70–80%. Above 80% signals liquidity pressure.
WITH monthly_loans AS (
    SELECT
        FORMAT(origination_date, 'yyyy-MM') AS report_month,
        SUM(outstanding_balance)            AS total_outstanding_loans
    FROM dbo.loans
    WHERE loan_status NOT IN ('Paid Off', 'Written Off')
    GROUP BY FORMAT(origination_date, 'yyyy-MM')
),
monthly_deposits AS (
    SELECT
        FORMAT(transaction_date, 'yyyy-MM') AS report_month,
        SUM(amount)                          AS total_deposits
    FROM dbo.transactions
    WHERE transaction_type IN ('Deposit', 'Direct Deposit')
      AND status = 'Completed'
    GROUP BY FORMAT(transaction_date, 'yyyy-MM')
)
SELECT
    ml.report_month,
    ml.total_outstanding_loans,
    md.total_deposits,
    CAST(ml.total_outstanding_loans / NULLIF(md.total_deposits, 0) * 100 AS DECIMAL(8,2)) AS ldr_pct,
    CASE
        WHEN (ml.total_outstanding_loans / NULLIF(md.total_deposits, 0)) BETWEEN 0.70 AND 0.80
            THEN 'Within Target'
        WHEN (ml.total_outstanding_loans / NULLIF(md.total_deposits, 0)) > 0.80
            THEN 'Above Target — Review Liquidity'
        ELSE 'Below Target — Underutilized'
    END AS ldr_status
FROM monthly_loans ml
JOIN monthly_deposits md ON ml.report_month = md.report_month
ORDER BY ml.report_month DESC;


-- 1b. Revenue by Product Line
--     Proxy: interest income from loans + transaction fees
--     In real system this would pull from GL; here we estimate from portfolio data.
SELECT
    loan_type                           AS product_line,
    COUNT(*)                            AS loan_count,
    SUM(loan_amount)                    AS total_originated,
    SUM(outstanding_balance)            AS total_outstanding,
    AVG(interest_rate)                  AS avg_interest_rate,
    -- Estimated annual interest income
    SUM(outstanding_balance * interest_rate) AS est_annual_interest_income,
    -- Portfolio share
    SUM(outstanding_balance) * 100.0 /
        SUM(SUM(outstanding_balance)) OVER () AS portfolio_share_pct
FROM dbo.loans
WHERE loan_status NOT IN ('Paid Off', 'Written Off')
  AND interest_rate IS NOT NULL
GROUP BY loan_type
ORDER BY est_annual_interest_income DESC;


-- 1c. Cost-to-Income Ratio by Region
--     Operating expenses from branch data vs estimated income
SELECT
    bp.region,
    SUM(bp.operating_expenses)              AS total_opex,
    SUM(bp.actual_deposits * 0.032)         AS est_net_interest_income,  -- 3.2% NIM proxy
    CAST(
        SUM(bp.operating_expenses) /
        NULLIF(SUM(bp.actual_deposits * 0.032), 0) * 100
    AS DECIMAL(8,2))                        AS cost_to_income_ratio_pct,
    CASE
        WHEN SUM(bp.operating_expenses) / NULLIF(SUM(bp.actual_deposits * 0.032), 0) <= 0.58
            THEN 'Efficient'
        ELSE 'Above Threshold — Investigate'
    END AS efficiency_status
FROM dbo.branch_performance bp
WHERE bp.report_month >= FORMAT(DATEADD(MONTH, -12, GETDATE()), 'yyyy-MM')
GROUP BY bp.region
ORDER BY cost_to_income_ratio_pct DESC;


-- ============================================================
-- SECTION 2 — RISK KPIs
-- ============================================================

-- 2a. Loan Delinquency Rate by Product Type and Region
--     Standard banking metric: all loans 30+ DPD / Total Active Loans
SELECT
    l.loan_type,
    c.region,
    COUNT(*)                                                            AS total_loans,
    SUM(CASE WHEN l.days_past_due >= 30 THEN 1 ELSE 0 END)            AS delinquent_loans,
    SUM(CASE WHEN l.days_past_due >= 30 THEN l.outstanding_balance
             ELSE 0 END)                                               AS delinquent_balance,
    SUM(l.outstanding_balance)                                         AS total_outstanding,
    CAST(
        SUM(CASE WHEN l.days_past_due >= 30 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(6,2))                                                    AS delinquency_rate_pct,
    CAST(
        SUM(CASE WHEN l.days_past_due >= 30 THEN l.outstanding_balance ELSE 0 END) * 100.0
        / NULLIF(SUM(l.outstanding_balance), 0)
    AS DECIMAL(6,2))                                                    AS delinquent_balance_pct
FROM dbo.loans l
JOIN dbo.customers c ON l.customer_id = c.customer_id
WHERE l.loan_status NOT IN ('Paid Off')
GROUP BY l.loan_type, c.region
ORDER BY delinquency_rate_pct DESC;


-- 2b. Non-Performing Loan (NPL) Ratio
--     Regulatory definition: loans 90+ DPD + Default + Written Off
SELECT
    loan_type,
    COUNT(*)                                                            AS total_loans,
    SUM(loan_amount)                                                    AS total_originated,
    SUM(outstanding_balance)                                            AS total_outstanding,
    SUM(CASE WHEN is_npl = 1 THEN outstanding_balance ELSE 0 END)      AS npl_balance,
    CAST(
        SUM(CASE WHEN is_npl = 1 THEN outstanding_balance ELSE 0 END) * 100.0
        / NULLIF(SUM(outstanding_balance), 0)
    AS DECIMAL(6,2))                                                    AS npl_ratio_pct,
    CASE
        WHEN SUM(CASE WHEN is_npl = 1 THEN outstanding_balance ELSE 0 END) /
             NULLIF(SUM(outstanding_balance), 0) <= 0.018
             THEN 'Within Threshold'
        ELSE 'ALERT — Exceeds 1.8% NPL Target'
    END AS npl_status
FROM dbo.loans
GROUP BY loan_type
ORDER BY npl_ratio_pct DESC;


-- 2c. Fraud Trend Analysis — Last 12 Months
SELECT
    FORMAT(rf.flag_date, 'yyyy-MM')         AS flag_month,
    rf.flag_category,
    rf.detection_method,
    COUNT(*)                                 AS total_flags,
    SUM(CASE WHEN rf.investigation_status = 'Confirmed Fraud'
             THEN 1 ELSE 0 END)              AS confirmed_fraud_count,
    SUM(rf.flagged_amount)                   AS total_flagged_amount,
    SUM(rf.loss_amount)                      AS total_confirmed_loss,
    AVG(rf.loss_amount)                      AS avg_loss_per_case,
    CAST(
        SUM(CASE WHEN rf.investigation_status = 'Confirmed Fraud'
                 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(6,2))                         AS fraud_confirmation_rate_pct
FROM dbo.risk_fraud_flags rf
WHERE rf.flag_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY FORMAT(rf.flag_date, 'yyyy-MM'), rf.flag_category, rf.detection_method
ORDER BY flag_month DESC, total_confirmed_loss DESC;


-- 2d. High-Risk Customer Concentration
--     Risk tiers 4 and 5 are considered elevated risk
SELECT
    risk_tier,
    customer_segment,
    region,
    COUNT(*)                                AS customer_count,
    AVG(credit_score)                       AS avg_credit_score,
    AVG(annual_income)                      AS avg_annual_income,
    COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER ()               AS pct_of_total_customers
FROM dbo.customers
WHERE is_active = 1
GROUP BY risk_tier, customer_segment, region
ORDER BY risk_tier DESC, customer_count DESC;


-- ============================================================
-- SECTION 3 — OPERATIONAL KPIs
-- ============================================================

-- 3a. Branch Deposit Attainment — Last 6 Months
SELECT
    bp.branch_id,
    b.city,
    b.state,
    bp.region,
    b.branch_type,
    AVG(bp.deposit_attainment) * 100        AS avg_attainment_pct,
    SUM(bp.actual_deposits)                 AS total_actual_deposits,
    SUM(bp.deposit_target)                  AS total_deposit_target,
    SUM(bp.new_accounts_opened)             AS total_new_accounts,
    SUM(bp.loan_originations)               AS total_loan_originations,
    AVG(bp.csat_score)                      AS avg_csat,
    AVG(bp.sla_adherence_rate) * 100        AS avg_sla_pct,
    -- Performance rank within region
    RANK() OVER (
        PARTITION BY bp.region
        ORDER BY AVG(bp.deposit_attainment) DESC
    )                                       AS regional_rank
FROM dbo.branch_performance bp
JOIN dbo.branches b ON bp.branch_id = b.branch_id
WHERE bp.report_month >= FORMAT(DATEADD(MONTH, -6, GETDATE()), 'yyyy-MM')
  AND b.is_active = 1
GROUP BY bp.branch_id, b.city, b.state, bp.region, b.branch_type
ORDER BY avg_attainment_pct DESC;


-- 3b. Digital vs Branch Transaction Split (Monthly)
SELECT
    FORMAT(transaction_date, 'yyyy-MM')     AS report_month,
    SUM(CASE WHEN channel IN ('Mobile App', 'Online Banking')
             THEN 1 ELSE 0 END)             AS digital_txn_count,
    SUM(CASE WHEN channel IN ('Branch', 'ATM')
             THEN 1 ELSE 0 END)             AS branch_txn_count,
    COUNT(*)                                AS total_txn_count,
    CAST(
        SUM(CASE WHEN channel IN ('Mobile App', 'Online Banking')
                 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)
    AS DECIMAL(6,2))                        AS digital_adoption_pct,
    SUM(CASE WHEN channel IN ('Mobile App', 'Online Banking')
             THEN amount ELSE 0 END)        AS digital_txn_volume,
    SUM(amount)                             AS total_txn_volume
FROM dbo.transactions
WHERE status = 'Completed'
  AND transaction_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY FORMAT(transaction_date, 'yyyy-MM')
ORDER BY report_month DESC;


-- ============================================================
-- SECTION 4 — CUSTOMER KPIs
-- ============================================================

-- 4a. Customer Segmentation Summary
SELECT
    c.customer_segment,
    c.risk_tier,
    COUNT(DISTINCT c.customer_id)               AS customer_count,
    AVG(c.annual_income)                         AS avg_income,
    AVG(c.credit_score)                          AS avg_credit_score,
    AVG(c.num_products)                          AS avg_products_held,
    -- Total loan exposure per segment
    SUM(l.outstanding_balance)                   AS total_loan_exposure,
    AVG(l.outstanding_balance)                   AS avg_loan_balance,
    -- Credit card utilization average
    AVG(cc.utilization_rate) * 100               AS avg_cc_utilization_pct,
    -- Digital adoption rate
    AVG(CAST(c.is_digital_customer AS FLOAT)) * 100 AS digital_adoption_pct
FROM dbo.customers c
LEFT JOIN dbo.loans l         ON c.customer_id = l.customer_id
                              AND l.loan_status NOT IN ('Paid Off', 'Written Off')
LEFT JOIN dbo.credit_cards cc ON c.customer_id = cc.customer_id
                              AND cc.is_active = 1
WHERE c.is_active = 1
GROUP BY c.customer_segment, c.risk_tier
ORDER BY c.customer_segment, c.risk_tier;


-- 4b. High-Utilization Credit Card Alert
--     Cards above 80% utilization — proactive outreach trigger
SELECT
    c.customer_id,
    c.customer_segment,
    c.risk_tier,
    c.region,
    cc.card_id,
    cc.card_type,
    cc.credit_limit,
    cc.current_balance,
    cc.utilization_rate * 100   AS utilization_pct,
    cc.payment_status,
    -- Days since account opened
    DATEDIFF(DAY, cc.open_date, GETDATE()) AS account_age_days
FROM dbo.customers c
JOIN dbo.credit_cards cc ON c.customer_id = cc.customer_id
WHERE cc.utilization_rate > 0.80
  AND cc.is_active = 1
  AND cc.payment_status NOT IN ('Charge-Off', 'Closed')
  AND c.is_active = 1
ORDER BY cc.utilization_rate DESC;


-- ============================================================
-- SECTION 5 — WINDOW FUNCTIONS & TREND ANALYSIS
-- ============================================================

-- 5a. Rolling 3-Month Transaction Volume by Region
WITH monthly_txn_volume AS (
    SELECT
        c.region,
        FORMAT(t.transaction_date, 'yyyy-MM')  AS report_month,
        COUNT(*)                                AS txn_count,
        SUM(t.amount)                           AS txn_volume,
        SUM(CASE WHEN t.is_fraud_flag = 1
                 THEN 1 ELSE 0 END)             AS fraud_flags
    FROM dbo.transactions t
    JOIN dbo.customers c ON t.customer_id = c.customer_id
    WHERE t.status = 'Completed'
    GROUP BY c.region, FORMAT(t.transaction_date, 'yyyy-MM')
)
SELECT
    region,
    report_month,
    txn_count,
    txn_volume,
    fraud_flags,
    -- 3-month rolling average
    AVG(txn_volume) OVER (
        PARTITION BY region
        ORDER BY report_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )                                           AS rolling_3mo_avg_volume,
    -- Month-over-month change
    LAG(txn_volume, 1) OVER (
        PARTITION BY region
        ORDER BY report_month
    )                                           AS prior_month_volume,
    txn_volume - LAG(txn_volume, 1) OVER (
        PARTITION BY region
        ORDER BY report_month
    )                                           AS mom_change
FROM monthly_txn_volume
ORDER BY region, report_month DESC;


-- 5b. Cumulative Fraud Losses YTD with Running Total
WITH fraud_monthly AS (
    SELECT
        FORMAT(flag_date, 'yyyy-MM')            AS flag_month,
        YEAR(flag_date)                          AS flag_year,
        SUM(loss_amount)                         AS monthly_loss,
        COUNT(*)                                 AS flag_count,
        SUM(CASE WHEN investigation_status = 'Confirmed Fraud'
                 THEN 1 ELSE 0 END)              AS confirmed_count
    FROM dbo.risk_fraud_flags
    GROUP BY FORMAT(flag_date, 'yyyy-MM'), YEAR(flag_date)
)
SELECT
    flag_month,
    flag_year,
    flag_count,
    confirmed_count,
    monthly_loss,
    -- Running YTD total per year
    SUM(monthly_loss) OVER (
        PARTITION BY flag_year
        ORDER BY flag_month
        ROWS UNBOUNDED PRECEDING
    )                                           AS ytd_cumulative_loss,
    -- Rank months by loss within each year
    RANK() OVER (
        PARTITION BY flag_year
        ORDER BY monthly_loss DESC
    )                                           AS loss_rank_in_year
FROM fraud_monthly
ORDER BY flag_month DESC;


-- 5c. Branch Performance Ranking with Percentiles
SELECT
    branch_id,
    region,
    state,
    AVG(deposit_attainment)     AS avg_attainment,
    AVG(csat_score)             AS avg_csat,
    SUM(loan_originations)      AS total_loan_originations,
    NTILE(4) OVER (
        ORDER BY AVG(deposit_attainment) DESC
    )                           AS performance_quartile,   -- 1=top, 4=bottom
    PERCENT_RANK() OVER (
        ORDER BY AVG(deposit_attainment) DESC
    )                           AS performance_percentile
FROM dbo.branch_performance
WHERE report_month >= FORMAT(DATEADD(MONTH, -6, GETDATE()), 'yyyy-MM')
GROUP BY branch_id, region, state
ORDER BY avg_attainment DESC;


-- ============================================================
-- SECTION 6 — GEOGRAPHIC RISK BREAKDOWN
-- ============================================================

-- 6a. State-Level Risk Heat Map Data
SELECT
    c.state,
    c.region,
    COUNT(DISTINCT c.customer_id)       AS total_customers,
    -- Loan risk
    COUNT(DISTINCT l.loan_id)           AS total_loans,
    SUM(CASE WHEN l.is_npl = 1
             THEN l.outstanding_balance ELSE 0 END) AS npl_balance,
    SUM(l.outstanding_balance)          AS total_loan_balance,
    CAST(
        SUM(CASE WHEN l.is_npl = 1
                 THEN l.outstanding_balance ELSE 0 END) * 100.0
        / NULLIF(SUM(l.outstanding_balance), 0)
    AS DECIMAL(6,2))                    AS npl_ratio_pct,
    -- Fraud exposure
    COUNT(DISTINCT rf.flag_id)          AS fraud_flags,
    SUM(rf.loss_amount)                 AS total_fraud_loss,
    -- Customer risk profile
    AVG(CAST(c.risk_tier AS FLOAT))     AS avg_risk_tier,
    AVG(c.credit_score)                 AS avg_credit_score
FROM dbo.customers c
LEFT JOIN dbo.loans l             ON c.customer_id = l.customer_id
LEFT JOIN dbo.transactions t      ON c.customer_id = t.customer_id
LEFT JOIN dbo.risk_fraud_flags rf ON t.transaction_id = rf.transaction_id
WHERE c.is_active = 1
GROUP BY c.state, c.region
ORDER BY npl_ratio_pct DESC NULLS LAST;

GO
PRINT 'KPI analysis queries complete.';
GO
