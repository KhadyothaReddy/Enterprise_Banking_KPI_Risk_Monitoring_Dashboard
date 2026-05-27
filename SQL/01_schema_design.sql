-- ============================================================
-- Apex Capital Bank — Enterprise Analytics Schema
-- File: 01_schema_design.sql
-- Author: BI & Data Engineering Team
-- Created: May 2026
-- Version: 1.1
--
-- Purpose:
--   Defines the analytical data mart schema used as the foundation
--   for all KPI and risk reporting. This is the "reporting layer"
--   sitting on top of the core banking system extracts.
--
-- Notes:
--   - This schema targets SQL Server (T-SQL syntax).
--   - Adjust data types for MySQL/PostgreSQL as needed.
--   - PII fields (name, etc.) are masked in this environment.
--   - All amounts in USD.
-- ============================================================

-- Create and use the analytics database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ACB_Analytics')
BEGIN
    CREATE DATABASE ACB_Analytics;
END;
GO

USE ACB_Analytics;
GO

-- ============================================================
-- DROP TABLES (if re-running this script)
-- Order matters because of foreign keys
-- ============================================================
IF OBJECT_ID('dbo.risk_fraud_flags', 'U') IS NOT NULL DROP TABLE dbo.risk_fraud_flags;
IF OBJECT_ID('dbo.credit_cards', 'U')     IS NOT NULL DROP TABLE dbo.credit_cards;
IF OBJECT_ID('dbo.branch_performance', 'U') IS NOT NULL DROP TABLE dbo.branch_performance;
IF OBJECT_ID('dbo.transactions', 'U')     IS NOT NULL DROP TABLE dbo.transactions;
IF OBJECT_ID('dbo.loans', 'U')            IS NOT NULL DROP TABLE dbo.loans;
IF OBJECT_ID('dbo.branches', 'U')         IS NOT NULL DROP TABLE dbo.branches;
IF OBJECT_ID('dbo.customers', 'U')        IS NOT NULL DROP TABLE dbo.customers;
GO


-- ============================================================
-- TABLE 1: customers
-- Core customer master table. One row per customer.
-- ============================================================
CREATE TABLE dbo.customers (
    customer_id         VARCHAR(15)     NOT NULL PRIMARY KEY,   -- ACB-C######
    first_name          VARCHAR(50)     NULL,                   -- Masked in prod
    last_name           VARCHAR(50)     NULL,                   -- Masked in prod
    age                 TINYINT         NULL,
    state               CHAR(2)         NOT NULL,
    region              VARCHAR(20)     NOT NULL,
    occupation          VARCHAR(50)     NULL,
    annual_income       DECIMAL(14,2)   NULL,
    credit_score        SMALLINT        NULL,
    customer_segment    VARCHAR(25)     NOT NULL,   -- Mass Market / Affluent / etc.
    risk_tier           TINYINT         NOT NULL,   -- 1 (low) to 5 (high)
    account_open_date   DATE            NOT NULL,
    is_digital_customer BIT             NOT NULL DEFAULT 0,
    num_products        TINYINT         NOT NULL DEFAULT 1,
    is_active           BIT             NOT NULL DEFAULT 1,
    -- Audit columns
    created_at          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    updated_at          DATETIME2       NULL,

    CONSTRAINT chk_risk_tier    CHECK (risk_tier BETWEEN 1 AND 5),
    CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 300 AND 850 OR credit_score IS NULL),
    CONSTRAINT chk_age          CHECK (age BETWEEN 18 AND 100 OR age IS NULL)
);
GO


-- ============================================================
-- TABLE 2: branches
-- Branch master — static attributes
-- ============================================================
CREATE TABLE dbo.branches (
    branch_id               VARCHAR(12)     NOT NULL PRIMARY KEY,
    branch_name             VARCHAR(100)    NOT NULL,
    city                    VARCHAR(50)     NOT NULL,
    state                   CHAR(2)         NOT NULL,
    region                  VARCHAR(20)     NOT NULL,
    branch_type             VARCHAR(20)     NOT NULL,   -- Full Service / Drive-Through / etc.
    num_employees           SMALLINT        NOT NULL,
    open_year               SMALLINT        NOT NULL,
    monthly_deposit_target  DECIMAL(18,2)   NOT NULL,
    is_active               BIT             NOT NULL DEFAULT 1,
    created_at              DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT chk_branch_type CHECK (branch_type IN ('Full Service','Drive-Through','In-Store','Corporate'))
);
GO


-- ============================================================
-- TABLE 3: transactions
-- Individual transaction-level data. High volume table.
-- ============================================================
CREATE TABLE dbo.transactions (
    transaction_id      VARCHAR(18)     NOT NULL PRIMARY KEY,
    customer_id         VARCHAR(15)     NOT NULL,
    branch_id           VARCHAR(12)     NULL,       -- NULL for digital-only transactions
    transaction_date    DATE            NOT NULL,
    transaction_type    VARCHAR(25)     NOT NULL,
    channel             VARCHAR(20)     NULL,
    amount              DECIMAL(18,2)   NOT NULL,
    status              VARCHAR(15)     NOT NULL DEFAULT 'Completed',
    is_fraud_flag       BIT             NOT NULL DEFAULT 0,
    currency            CHAR(3)         NOT NULL DEFAULT 'USD',
    created_at          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_txn_customer FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
    CONSTRAINT fk_txn_branch   FOREIGN KEY (branch_id)   REFERENCES dbo.branches(branch_id),
    CONSTRAINT chk_txn_amount  CHECK (amount > 0),
    CONSTRAINT chk_txn_status  CHECK (status IN ('Completed','Pending','Reversed','Failed'))
);
GO

-- Index for common query patterns
CREATE NONCLUSTERED INDEX ix_txn_customer_date
    ON dbo.transactions (customer_id, transaction_date);

CREATE NONCLUSTERED INDEX ix_txn_date_fraud
    ON dbo.transactions (transaction_date, is_fraud_flag)
    INCLUDE (amount, transaction_type);
GO


-- ============================================================
-- TABLE 4: loans
-- Loan portfolio table. One row per loan account.
-- ============================================================
CREATE TABLE dbo.loans (
    loan_id             VARCHAR(15)     NOT NULL PRIMARY KEY,
    customer_id         VARCHAR(15)     NOT NULL,
    loan_type           VARCHAR(25)     NOT NULL,
    origination_date    DATE            NOT NULL,
    loan_amount         DECIMAL(18,2)   NOT NULL,
    outstanding_balance DECIMAL(18,2)   NOT NULL,
    interest_rate       DECIMAL(6,4)    NULL,   -- e.g., 0.0725 = 7.25%
    term_months         SMALLINT        NULL,
    loan_status         VARCHAR(20)     NOT NULL DEFAULT 'Current',
    days_past_due       SMALLINT        NOT NULL DEFAULT 0,
    is_npl              BIT             NOT NULL DEFAULT 0,
    branch_originated   VARCHAR(12)     NULL,
    created_at          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),
    updated_at          DATETIME2       NULL,

    CONSTRAINT fk_loan_customer FOREIGN KEY (customer_id)       REFERENCES dbo.customers(customer_id),
    CONSTRAINT fk_loan_branch   FOREIGN KEY (branch_originated) REFERENCES dbo.branches(branch_id),
    CONSTRAINT chk_loan_status  CHECK (loan_status IN ('Current','30-59 DPD','60-89 DPD',
                                                        '90+ DPD','Default','Paid Off','Written Off')),
    CONSTRAINT chk_loan_dpd     CHECK (days_past_due >= 0),
    CONSTRAINT chk_loan_amount  CHECK (loan_amount > 0)
);
GO

CREATE NONCLUSTERED INDEX ix_loans_customer
    ON dbo.loans (customer_id);

CREATE NONCLUSTERED INDEX ix_loans_status_type
    ON dbo.loans (loan_status, loan_type)
    INCLUDE (loan_amount, outstanding_balance, days_past_due);
GO


-- ============================================================
-- TABLE 5: credit_cards
-- Credit card account table. One row per card account.
-- ============================================================
CREATE TABLE dbo.credit_cards (
    card_id             VARCHAR(15)     NOT NULL PRIMARY KEY,
    customer_id         VARCHAR(15)     NOT NULL,
    card_type           VARCHAR(15)     NOT NULL,
    credit_limit        DECIMAL(12,2)   NOT NULL,
    current_balance     DECIMAL(12,2)   NOT NULL DEFAULT 0,
    utilization_rate    DECIMAL(5,4)    NULL,   -- 0.0000 to 1.0000
    open_date           DATE            NOT NULL,
    payment_status      VARCHAR(15)     NOT NULL DEFAULT 'Current',
    reward_points       INT             NOT NULL DEFAULT 0,
    is_active           BIT             NOT NULL DEFAULT 1,
    annual_fee          DECIMAL(8,2)    NOT NULL DEFAULT 0,
    created_at          DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_cc_customer    FOREIGN KEY (customer_id) REFERENCES dbo.customers(customer_id),
    CONSTRAINT chk_cc_util       CHECK (utilization_rate BETWEEN 0 AND 1.0 OR utilization_rate IS NULL),
    CONSTRAINT chk_cc_limit      CHECK (credit_limit > 0),
    CONSTRAINT chk_cc_status     CHECK (payment_status IN ('Current','30 DPD','60 DPD',
                                                            '90+ DPD','Charge-Off','Closed'))
);
GO


-- ============================================================
-- TABLE 6: branch_performance
-- Monthly aggregated branch performance metrics.
-- ============================================================
CREATE TABLE dbo.branch_performance (
    perf_id                 INT             NOT NULL IDENTITY(1,1) PRIMARY KEY,
    branch_id               VARCHAR(12)     NOT NULL,
    report_month            CHAR(7)         NOT NULL,   -- Format: YYYY-MM
    actual_deposits         DECIMAL(18,2)   NOT NULL,
    deposit_target          DECIMAL(18,2)   NOT NULL,
    deposit_attainment      DECIMAL(6,4)    NOT NULL,   -- Actual / Target ratio
    new_accounts_opened     SMALLINT        NOT NULL DEFAULT 0,
    loan_originations       SMALLINT        NOT NULL DEFAULT 0,
    operating_expenses      DECIMAL(18,2)   NOT NULL,
    num_employees           SMALLINT        NOT NULL,
    revenue_per_employee    DECIMAL(14,2)   NULL,
    csat_score              DECIMAL(3,1)    NULL,
    sla_adherence_rate      DECIMAL(5,4)    NULL,
    state                   CHAR(2)         NOT NULL,
    region                  VARCHAR(20)     NOT NULL,

    CONSTRAINT fk_perf_branch FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id),
    CONSTRAINT uq_branch_month UNIQUE (branch_id, report_month)
);
GO

CREATE NONCLUSTERED INDEX ix_perf_month_region
    ON dbo.branch_performance (report_month, region)
    INCLUDE (actual_deposits, deposit_attainment, loan_originations);
GO


-- ============================================================
-- TABLE 7: risk_fraud_flags
-- Fraud and risk flag records linked to transactions.
-- ============================================================
CREATE TABLE dbo.risk_fraud_flags (
    flag_id                 VARCHAR(15)     NOT NULL PRIMARY KEY,
    transaction_id          VARCHAR(18)     NOT NULL,
    customer_id             VARCHAR(15)     NOT NULL,
    flag_date               DATE            NOT NULL,
    flag_category           VARCHAR(35)     NOT NULL,
    flagged_amount          DECIMAL(18,2)   NOT NULL,
    investigation_status    VARCHAR(20)     NOT NULL DEFAULT 'Pending',
    loss_amount             DECIMAL(18,2)   NOT NULL DEFAULT 0,
    detection_method        VARCHAR(20)     NOT NULL,
    created_at              DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_flag_txn      FOREIGN KEY (transaction_id) REFERENCES dbo.transactions(transaction_id),
    CONSTRAINT fk_flag_customer FOREIGN KEY (customer_id)    REFERENCES dbo.customers(customer_id),
    CONSTRAINT chk_flag_status  CHECK (investigation_status IN ('Under Review','Confirmed Fraud',
                                                                  'False Positive','Pending')),
    CONSTRAINT chk_loss_amount  CHECK (loss_amount >= 0)
);
GO

CREATE NONCLUSTERED INDEX ix_flags_date_category
    ON dbo.risk_fraud_flags (flag_date, flag_category)
    INCLUDE (flagged_amount, loss_amount, investigation_status);
GO


PRINT 'ACB_Analytics schema created successfully.';
GO
