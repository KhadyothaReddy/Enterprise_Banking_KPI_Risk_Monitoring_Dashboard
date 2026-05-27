-- ============================================================
-- Apex Capital Bank — Data Cleaning & Quality Checks
-- File: 02_data_cleaning.sql
-- Author: Data Engineering / BI Team
-- Created: May 2026
--
-- Purpose:
--   Standardizes, deduplicates, and validates all source data
--   before it flows into the reporting layer.
--   Run AFTER data load, BEFORE KPI queries.
--
-- Think of this as the "quality gate" — everything downstream
-- depends on this being clean and documented.
-- ============================================================

USE ACB_Analytics;
GO

-- ============================================================
-- SECTION 1 — DUPLICATE DETECTION & REMOVAL
-- ============================================================

-- 1a. Find duplicate customers (same customer_id appearing more than once)
-- This happens during multi-source ETL merges
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM dbo.customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 1b. Remove duplicate customers — keep the first loaded record
WITH customer_dedup AS (
    SELECT
        customer_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY created_at ASC  -- Keep earliest record
        ) AS rn
    FROM dbo.customers
)
DELETE FROM dbo.customers
WHERE customer_id IN (
    SELECT customer_id FROM customer_dedup WHERE rn > 1
);

-- 1c. Same dedup logic for transactions
-- Note: For transactions, we check on transaction_id (PK should catch this,
-- but ETL sometimes bypasses constraints)
WITH txn_dedup AS (
    SELECT
        transaction_id,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY created_at ASC
        ) AS rn
    FROM dbo.transactions
)
DELETE FROM dbo.transactions
WHERE transaction_id IN (
    SELECT transaction_id FROM txn_dedup WHERE rn > 1
);

-- 1d. Dedup loans
WITH loan_dedup AS (
    SELECT
        loan_id,
        ROW_NUMBER() OVER (
            PARTITION BY loan_id
            ORDER BY created_at ASC
        ) AS rn
    FROM dbo.loans
)
DELETE FROM dbo.loans
WHERE loan_id IN (
    SELECT loan_id FROM loan_dedup WHERE rn > 1
);


-- ============================================================
-- SECTION 2 — NULL HANDLING & IMPUTATION
-- ============================================================

-- 2a. Credit score — impute nulls with segment median
--     Rather than dropping these records, we flag them.
--     Analytics downstream can exclude flagged records if needed.

-- Step 1: Calculate segment medians
WITH segment_medians AS (
    SELECT
        customer_segment,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY credit_score)
            OVER (PARTITION BY customer_segment) AS median_credit_score
    FROM dbo.customers
    WHERE credit_score IS NOT NULL
)
-- Step 2: Update nulls
UPDATE c
SET
    c.credit_score = CAST(sm.median_credit_score AS SMALLINT),
    c.updated_at   = SYSDATETIME()
FROM dbo.customers c
JOIN (
    SELECT DISTINCT customer_segment, CAST(median_credit_score AS SMALLINT) AS median_score
    FROM segment_medians
) sm ON c.customer_segment = sm.customer_segment
WHERE c.credit_score IS NULL;

-- 2b. Annual income nulls — impute with segment median
UPDATE c
SET
    c.annual_income = seg_median.med_income,
    c.updated_at    = SYSDATETIME()
FROM dbo.customers c
JOIN (
    SELECT
        customer_segment,
        AVG(annual_income) AS med_income   -- Using avg as proxy; refine with PERCENTILE_CONT if needed
    FROM dbo.customers
    WHERE annual_income IS NOT NULL
    GROUP BY customer_segment
) seg_median ON c.customer_segment = seg_median.customer_segment
WHERE c.annual_income IS NULL;

-- 2c. Occupation nulls — set to 'Unknown' (not enough info to impute)
UPDATE dbo.customers
SET occupation = 'Unknown',
    updated_at = SYSDATETIME()
WHERE occupation IS NULL;

-- 2d. Transaction channel nulls — label as 'Unknown Channel'
UPDATE dbo.transactions
SET channel = 'Unknown Channel'
WHERE channel IS NULL;

-- 2e. Loan interest rate nulls — impute with loan type average
UPDATE l
SET
    l.interest_rate = lt_avg.avg_rate,
    l.updated_at    = SYSDATETIME()
FROM dbo.loans l
JOIN (
    SELECT loan_type, AVG(interest_rate) AS avg_rate
    FROM dbo.loans
    WHERE interest_rate IS NOT NULL
    GROUP BY loan_type
) lt_avg ON l.loan_type = lt_avg.loan_type
WHERE l.interest_rate IS NULL;


-- ============================================================
-- SECTION 3 — ANOMALY DETECTION & OUTLIER FLAGGING
-- ============================================================

-- 3a. Flag transactions with suspiciously large amounts
--     We don't delete them — we flag for downstream review.
--     Threshold: > $500,000 for a single transaction
ALTER TABLE dbo.transactions ADD is_outlier_amount BIT NULL DEFAULT 0;
GO

UPDATE dbo.transactions
SET is_outlier_amount = 1
WHERE amount > 500000;

-- How many flagged?
SELECT COUNT(*) AS large_txn_count
FROM dbo.transactions
WHERE is_outlier_amount = 1;

-- 3b. Flag customers with unrealistic ages
SELECT customer_id, age
FROM dbo.customers
WHERE age < 18 OR age > 100;

-- Fix: cap at boundaries (these are data entry errors, not fraud)
UPDATE dbo.customers
SET age = 18, updated_at = SYSDATETIME()
WHERE age < 18;

UPDATE dbo.customers
SET age = 100, updated_at = SYSDATETIME()
WHERE age > 100;

-- 3c. Negative outstanding loan balances (shouldn't exist — flag as data issue)
SELECT loan_id, outstanding_balance
FROM dbo.loans
WHERE outstanding_balance < 0;

UPDATE dbo.loans
SET outstanding_balance = ABS(outstanding_balance),
    updated_at = SYSDATETIME()
WHERE outstanding_balance < 0;

-- 3d. Credit utilization > 100% (possible if over-limit spending allowed)
--     Flag but don't delete
SELECT card_id, utilization_rate
FROM dbo.credit_cards
WHERE utilization_rate > 1.0;


-- ============================================================
-- SECTION 4 — REFERENTIAL INTEGRITY CHECKS
-- ============================================================

-- 4a. Transactions without a valid customer_id
SELECT COUNT(*) AS orphan_transactions
FROM dbo.transactions t
LEFT JOIN dbo.customers c ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 4b. Loans referencing inactive or missing customers
SELECT l.loan_id, l.customer_id
FROM dbo.loans l
LEFT JOIN dbo.customers c ON l.customer_id = c.customer_id
WHERE c.customer_id IS NULL
   OR c.is_active = 0;

-- 4c. Risk flags referencing missing transactions
SELECT rf.flag_id
FROM dbo.risk_fraud_flags rf
LEFT JOIN dbo.transactions t ON rf.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;


-- ============================================================
-- SECTION 5 — DATA QUALITY SCORECARD
-- Run this at the end to validate the cleaning process
-- ============================================================
SELECT
    'customers'     AS table_name,
    COUNT(*)        AS total_rows,
    SUM(CASE WHEN credit_score IS NULL  THEN 1 ELSE 0 END) AS null_credit_score,
    SUM(CASE WHEN annual_income IS NULL THEN 1 ELSE 0 END) AS null_income,
    SUM(CASE WHEN occupation = 'Unknown' THEN 1 ELSE 0 END) AS unknown_occupation
FROM dbo.customers

UNION ALL

SELECT
    'transactions',
    COUNT(*),
    SUM(CASE WHEN channel = 'Unknown Channel' THEN 1 ELSE 0 END),
    SUM(CASE WHEN is_outlier_amount = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN is_fraud_flag = 1 THEN 1 ELSE 0 END)
FROM dbo.transactions

UNION ALL

SELECT
    'loans',
    COUNT(*),
    SUM(CASE WHEN interest_rate IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN is_npl = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN loan_status = 'Default' THEN 1 ELSE 0 END)
FROM dbo.loans;

GO
PRINT 'Data cleaning complete. Review quality scorecard above.';
GO
