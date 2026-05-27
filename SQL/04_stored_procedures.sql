-- ============================================================
-- Apex Capital Bank — Stored Procedures
-- File: 04_stored_procedures.sql
-- Author: Data Engineering Team
-- Created: May 2026
--
-- Purpose:
--   Reusable stored procedures for scheduled reporting,
--   dashboard data refresh, and ad-hoc executive requests.
--   These are called by the ETL scheduler and Power BI
--   DirectQuery refresh jobs.
-- ============================================================

USE ACB_Analytics;
GO


-- ============================================================
-- SP 1: usp_GetBranchPerformanceSummary
-- Returns branch-level KPI summary for a given month range.
-- Called by: Power BI Operations Dashboard (refresh)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_GetBranchPerformanceSummary
    @StartMonth     CHAR(7),        -- Format: YYYY-MM
    @EndMonth       CHAR(7),        -- Format: YYYY-MM
    @Region         VARCHAR(20) = NULL   -- Optional filter; NULL = all regions
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bp.branch_id,
        b.branch_name,
        b.city,
        b.state,
        bp.region,
        b.branch_type,
        b.num_employees,
        COUNT(bp.report_month)                      AS months_reported,
        SUM(bp.actual_deposits)                     AS total_actual_deposits,
        SUM(bp.deposit_target)                      AS total_deposit_target,
        CAST(
            SUM(bp.actual_deposits) * 100.0 /
            NULLIF(SUM(bp.deposit_target), 0)
        AS DECIMAL(8,2))                            AS overall_attainment_pct,
        SUM(bp.new_accounts_opened)                 AS total_new_accounts,
        SUM(bp.loan_originations)                   AS total_loan_originations,
        SUM(bp.operating_expenses)                  AS total_opex,
        AVG(bp.csat_score)                          AS avg_csat_score,
        AVG(bp.sla_adherence_rate) * 100            AS avg_sla_adherence_pct,
        AVG(bp.revenue_per_employee)                AS avg_rev_per_employee,
        -- Flag underperformers
        CASE
            WHEN SUM(bp.actual_deposits) /
                 NULLIF(SUM(bp.deposit_target), 0) < 0.90
                 THEN 'Underperforming'
            WHEN SUM(bp.actual_deposits) /
                 NULLIF(SUM(bp.deposit_target), 0) BETWEEN 0.90 AND 1.05
                 THEN 'On Track'
            ELSE 'Outperforming'
        END                                         AS performance_flag
    FROM dbo.branch_performance bp
    JOIN dbo.branches b ON bp.branch_id = b.branch_id
    WHERE bp.report_month BETWEEN @StartMonth AND @EndMonth
      AND b.is_active = 1
      AND (@Region IS NULL OR bp.region = @Region)
    GROUP BY
        bp.branch_id, b.branch_name, b.city, b.state,
        bp.region, b.branch_type, b.num_employees
    ORDER BY overall_attainment_pct DESC;

END;
GO

-- Test it:
-- EXEC dbo.usp_GetBranchPerformanceSummary '2025-10', '2026-03', NULL;
-- EXEC dbo.usp_GetBranchPerformanceSummary '2025-10', '2026-03', 'Southeast';


-- ============================================================
-- SP 2: usp_GetLoanRiskReport
-- Delinquency and NPL summary for the risk dashboard.
-- Called by: CRO weekly risk review, Power BI Risk Dashboard
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_GetLoanRiskReport
    @AsOfDate   DATE = NULL,    -- Default to today
    @LoanType   VARCHAR(25) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
        SET @AsOfDate = CAST(GETDATE() AS DATE);

    WITH loan_risk_base AS (
        SELECT
            l.loan_id,
            l.customer_id,
            l.loan_type,
            l.loan_amount,
            l.outstanding_balance,
            l.interest_rate,
            l.loan_status,
            l.days_past_due,
            l.is_npl,
            c.region,
            c.state,
            c.risk_tier,
            c.customer_segment,
            -- Delinquency bucket
            CASE
                WHEN l.days_past_due = 0          THEN 'Current'
                WHEN l.days_past_due BETWEEN 1 AND 29   THEN '1-29 DPD'
                WHEN l.days_past_due BETWEEN 30 AND 59  THEN '30-59 DPD'
                WHEN l.days_past_due BETWEEN 60 AND 89  THEN '60-89 DPD'
                WHEN l.days_past_due >= 90        THEN '90+ DPD'
                ELSE 'Unknown'
            END AS delinquency_bucket
        FROM dbo.loans l
        JOIN dbo.customers c ON l.customer_id = c.customer_id
        WHERE l.loan_status NOT IN ('Paid Off')
          AND l.origination_date <= @AsOfDate
          AND (@LoanType IS NULL OR l.loan_type = @LoanType)
    )
    SELECT
        loan_type,
        region,
        risk_tier,
        delinquency_bucket,
        COUNT(*)                    AS loan_count,
        SUM(outstanding_balance)    AS total_outstanding,
        AVG(outstanding_balance)    AS avg_balance,
        AVG(days_past_due)          AS avg_dpd,
        SUM(CASE WHEN is_npl = 1
                 THEN outstanding_balance ELSE 0 END) AS npl_exposure,
        CAST(
            SUM(CASE WHEN is_npl = 1
                     THEN outstanding_balance ELSE 0 END) * 100.0
            / NULLIF(SUM(outstanding_balance), 0)
        AS DECIMAL(6,2))            AS npl_ratio_pct
    FROM loan_risk_base
    GROUP BY loan_type, region, risk_tier, delinquency_bucket
    ORDER BY loan_type, delinquency_bucket, region;

END;
GO

-- Test:
-- EXEC dbo.usp_GetLoanRiskReport NULL, NULL;
-- EXEC dbo.usp_GetLoanRiskReport '2026-03-31', 'Mortgage';


-- ============================================================
-- SP 3: usp_FraudSummaryByPeriod
-- Fraud KPIs for a given date range.
-- Called by: Fraud Operations team, daily automated report
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_FraudSummaryByPeriod
    @StartDate      DATE,
    @EndDate        DATE,
    @DetectionMethod VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FORMAT(rf.flag_date, 'yyyy-MM')             AS period_month,
        rf.flag_category,
        rf.detection_method,
        rf.investigation_status,
        COUNT(*)                                     AS flag_count,
        SUM(rf.flagged_amount)                       AS total_flagged_amount,
        SUM(rf.loss_amount)                          AS total_confirmed_loss,
        AVG(rf.loss_amount)                          AS avg_loss_per_case,
        -- False positive rate (want this LOW — indicates good model precision)
        CAST(
            SUM(CASE WHEN rf.investigation_status = 'False Positive'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2))                             AS false_positive_rate_pct,
        -- Detection precision
        CAST(
            SUM(CASE WHEN rf.investigation_status = 'Confirmed Fraud'
                     THEN 1 ELSE 0 END) * 100.0
            / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2))                             AS detection_precision_pct
    FROM dbo.risk_fraud_flags rf
    WHERE rf.flag_date BETWEEN @StartDate AND @EndDate
      AND (@DetectionMethod IS NULL OR rf.detection_method = @DetectionMethod)
    GROUP BY
        FORMAT(rf.flag_date, 'yyyy-MM'),
        rf.flag_category,
        rf.detection_method,
        rf.investigation_status
    ORDER BY period_month DESC, total_confirmed_loss DESC;

END;
GO

-- Test:
-- EXEC dbo.usp_FraudSummaryByPeriod '2025-01-01', '2026-03-31', NULL;
-- EXEC dbo.usp_FraudSummaryByPeriod '2026-01-01', '2026-03-31', 'ML Model';


-- ============================================================
-- SP 4: usp_CustomerRiskProfile
-- Returns full risk profile for a given customer.
-- Used by: Relationship Managers for account review
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_CustomerRiskProfile
    @CustomerID VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    -- Customer basics
    SELECT
        c.customer_id,
        c.customer_segment,
        c.risk_tier,
        c.credit_score,
        c.annual_income,
        c.region,
        c.state,
        c.num_products,
        c.is_digital_customer,
        c.account_open_date,
        DATEDIFF(MONTH, c.account_open_date, GETDATE()) AS tenure_months
    FROM dbo.customers c
    WHERE c.customer_id = @CustomerID;

    -- Loan summary
    SELECT
        loan_type,
        loan_amount,
        outstanding_balance,
        interest_rate,
        loan_status,
        days_past_due,
        is_npl
    FROM dbo.loans
    WHERE customer_id = @CustomerID
    ORDER BY origination_date DESC;

    -- Credit card summary
    SELECT
        card_type,
        credit_limit,
        current_balance,
        utilization_rate * 100  AS utilization_pct,
        payment_status,
        reward_points
    FROM dbo.credit_cards
    WHERE customer_id = @CustomerID
      AND is_active = 1;

    -- Last 10 transactions
    SELECT TOP 10
        transaction_date,
        transaction_type,
        channel,
        amount,
        status,
        is_fraud_flag
    FROM dbo.transactions
    WHERE customer_id = @CustomerID
    ORDER BY transaction_date DESC;

    -- Fraud flags history
    SELECT
        flag_date,
        flag_category,
        flagged_amount,
        loss_amount,
        investigation_status,
        detection_method
    FROM dbo.risk_fraud_flags
    WHERE customer_id = @CustomerID
    ORDER BY flag_date DESC;

END;
GO

-- Test:
-- EXEC dbo.usp_CustomerRiskProfile 'ACB-C000001';


PRINT 'Stored procedures created successfully.';
GO
