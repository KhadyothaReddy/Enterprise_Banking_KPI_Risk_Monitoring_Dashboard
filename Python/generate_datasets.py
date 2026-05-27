"""
generate_datasets.py
Apex Capital Bank — Enterprise KPI & Risk Monitoring
-----------------------------------------------------
Purpose:
    Generates all synthetic banking datasets needed for the dashboard project.
    Data is modeled to reflect realistic banking patterns including seasonal
    trends, geographic variation, risk clustering, and fraud behavior.

    All data is SYNTHETIC — no real customer information is used.

Author: Analytics & Strategy Team, Business Intelligence Division
Created: May 2026
Version: 1.0

Notes:
    - Run this script ONCE to generate all CSVs.
    - Output goes to the /Dataset folder.
    - Seed is fixed (seed=42) so results are reproducible.
    - Intentional missing values and anomalies are added to simulate real data quality issues.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os
import warnings
warnings.filterwarnings('ignore')

# ----------------------------
# CONFIG
# ----------------------------
np.random.seed(42)
random.seed(42)

N_CUSTOMERS     = 15000   # Total customers
N_TRANSACTIONS  = 120000  # Transaction records
N_LOANS         = 8000    # Loan records
N_CREDIT_CARDS  = 10000   # Credit card accounts
N_BRANCHES      = 80      # Branch count
START_DATE      = datetime(2023, 1, 1)
END_DATE        = datetime(2026, 3, 31)

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'Dataset')
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("="*60)
print("Apex Capital Bank — Dataset Generation")
print("="*60)


# ----------------------------
# HELPER FUNCTIONS
# ----------------------------

def random_date(start, end):
    """Returns a random datetime between start and end."""
    delta = end - start
    rand_days = random.randint(0, delta.days)
    return start + timedelta(days=rand_days)

def add_missing_values(df, cols, pct=0.02):
    """
    Introduces realistic missing values into specified columns.
    Real banking data ALWAYS has some nulls — skipped fields,
    system migration gaps, optional form fields left blank, etc.
    Typical rate: 1-3% for core fields, up to 8% for optional fields.
    """
    for col in cols:
        null_idx = df.sample(frac=pct).index
        df.loc[null_idx, col] = np.nan
    return df

def add_duplicates(df, n=15):
    """
    Adds a small number of duplicate rows.
    This is intentional — mirrors what happens when ETL jobs re-run
    or when records are loaded from multiple source systems.
    Analysts are expected to de-dup as part of cleaning.
    """
    dup_rows = df.sample(n=n)
    df = pd.concat([df, dup_rows], ignore_index=True)
    return df


# ============================================================
# DATASET 1 — CUSTOMERS
# ============================================================
print("\n[1/7] Generating Customer Data...")

states = ['TX', 'CA', 'FL', 'NY', 'GA', 'NC', 'OH', 'IL', 'AZ', 'TN',
          'VA', 'PA']
state_weights = [0.14, 0.13, 0.12, 0.10, 0.09, 0.08, 0.07, 0.07, 0.06, 0.06, 0.05, 0.03]

regions = {
    'TX': 'South', 'CA': 'West', 'FL': 'Southeast', 'NY': 'Northeast',
    'GA': 'Southeast', 'NC': 'Southeast', 'OH': 'Midwest', 'IL': 'Midwest',
    'AZ': 'West', 'TN': 'South', 'VA': 'Northeast', 'PA': 'Northeast'
}

customer_segments = ['Mass Market', 'Emerging Affluent', 'Affluent', 'High Net Worth']
seg_weights = [0.55, 0.25, 0.15, 0.05]

risk_tiers = [1, 2, 3, 4, 5]  # 1=lowest risk, 5=highest risk
risk_weights = [0.20, 0.30, 0.28, 0.14, 0.08]

occupations = [
    'Employed - Full Time', 'Employed - Part Time', 'Self-Employed',
    'Retired', 'Student', 'Unemployed', 'Government Employee'
]

first_names = ['James', 'Maria', 'Robert', 'Linda', 'Michael', 'Barbara',
               'David', 'Patricia', 'John', 'Jennifer', 'Charles', 'Susan',
               'Thomas', 'Jessica', 'Kevin', 'Sarah', 'Mark', 'Karen',
               'Daniel', 'Nancy', 'Angela', 'Diana', 'Carlos', 'Aisha',
               'Priya', 'Wei', 'Hassan', 'Elena', 'Marcus', 'Fatima']

last_names = ['Johnson', 'Smith', 'Williams', 'Brown', 'Jones', 'Garcia',
              'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez',
              'Lopez', 'Wilson', 'Anderson', 'Taylor', 'Thomas', 'Moore',
              'Jackson', 'Martin', 'Lee', 'Patel', 'Kim', 'Nguyen',
              'Chen', 'Ahmed', 'Okafor', 'Russo', 'Kowalski', 'Singh', 'Park']

customer_ids = [f'ACB-C{str(i).zfill(6)}' for i in range(1, N_CUSTOMERS + 1)]

cust_state       = np.random.choice(states, size=N_CUSTOMERS, p=state_weights)
cust_segment     = np.random.choice(customer_segments, size=N_CUSTOMERS, p=seg_weights)
cust_risk_tier   = np.random.choice(risk_tiers, size=N_CUSTOMERS, p=risk_weights)
cust_occupation  = np.random.choice(occupations, size=N_CUSTOMERS)

# Income correlates with segment — more realistic than random
def income_by_segment(seg):
    if seg == 'Mass Market':
        return round(np.random.lognormal(10.7, 0.4), 2)       # ~$44k avg
    elif seg == 'Emerging Affluent':
        return round(np.random.lognormal(11.2, 0.35), 2)      # ~$73k avg
    elif seg == 'Affluent':
        return round(np.random.lognormal(11.8, 0.3), 2)       # ~$133k avg
    else:
        return round(np.random.lognormal(12.5, 0.4), 2)       # ~$269k avg

# Credit score also loosely tied to risk tier
def credit_score_by_risk(risk):
    base = {1: (750, 30), 2: (710, 35), 3: (660, 40), 4: (610, 45), 5: (560, 50)}
    mu, sigma = base[risk]
    score = int(np.random.normal(mu, sigma))
    return max(300, min(850, score))

annual_incomes   = [income_by_segment(s) for s in cust_segment]
credit_scores    = [credit_score_by_risk(r) for r in cust_risk_tier]
account_open_dates = [random_date(datetime(2015, 1, 1), END_DATE) for _ in range(N_CUSTOMERS)]
is_digital       = np.random.choice([1, 0], size=N_CUSTOMERS, p=[0.67, 0.33])

# Age: slight variation by segment
ages = []
for seg in cust_segment:
    if seg == 'Mass Market':
        ages.append(int(np.random.normal(38, 12)))
    elif seg == 'Emerging Affluent':
        ages.append(int(np.random.normal(42, 10)))
    elif seg == 'Affluent':
        ages.append(int(np.random.normal(50, 11)))
    else:
        ages.append(int(np.random.normal(58, 10)))
ages = [max(18, min(85, a)) for a in ages]

fn = [random.choice(first_names) for _ in range(N_CUSTOMERS)]
ln = [random.choice(last_names) for _ in range(N_CUSTOMERS)]

customers_df = pd.DataFrame({
    'customer_id':        customer_ids,
    'first_name':         fn,
    'last_name':          ln,
    'age':                ages,
    'state':              cust_state,
    'region':             [regions[s] for s in cust_state],
    'occupation':         cust_occupation,
    'annual_income':      annual_incomes,
    'credit_score':       credit_scores,
    'customer_segment':   cust_segment,
    'risk_tier':          cust_risk_tier,
    'account_open_date':  [d.strftime('%Y-%m-%d') for d in account_open_dates],
    'is_digital_customer': is_digital,
    'num_products':       np.random.choice([1, 2, 3, 4, 5], size=N_CUSTOMERS,
                                           p=[0.20, 0.30, 0.25, 0.15, 0.10]),
    'is_active':          np.random.choice([1, 0], size=N_CUSTOMERS, p=[0.93, 0.07])
})

# Introduce realistic nulls and a few duplicates
customers_df = add_missing_values(customers_df, ['occupation', 'annual_income'], pct=0.025)
customers_df = add_missing_values(customers_df, ['credit_score'], pct=0.015)
customers_df = add_duplicates(customers_df, n=12)

customers_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_customers.csv'), index=False)
print(f"  -> acb_customers.csv saved ({len(customers_df):,} rows)")


# ============================================================
# DATASET 2 — BRANCHES
# ============================================================
print("\n[2/7] Generating Branch Data...")

branch_ids = [f'ACB-BR{str(i).zfill(3)}' for i in range(1, N_BRANCHES + 1)]

branch_cities_by_state = {
    'TX': ['Houston', 'Dallas', 'San Antonio', 'Austin', 'Fort Worth'],
    'CA': ['Los Angeles', 'San Diego', 'San Jose', 'San Francisco', 'Fresno'],
    'FL': ['Jacksonville', 'Miami', 'Tampa', 'Orlando', 'St. Petersburg'],
    'NY': ['New York City', 'Buffalo', 'Rochester', 'Albany', 'Syracuse'],
    'GA': ['Atlanta', 'Augusta', 'Columbus', 'Macon', 'Savannah'],
    'NC': ['Charlotte', 'Raleigh', 'Greensboro', 'Durham', 'Winston-Salem'],
    'OH': ['Columbus', 'Cleveland', 'Cincinnati', 'Toledo', 'Akron'],
    'IL': ['Chicago', 'Aurora', 'Rockford', 'Joliet', 'Naperville'],
    'AZ': ['Phoenix', 'Tucson', 'Mesa', 'Chandler', 'Scottsdale'],
    'TN': ['Nashville', 'Memphis', 'Knoxville', 'Chattanooga', 'Clarksville'],
    'VA': ['Virginia Beach', 'Norfolk', 'Chesapeake', 'Richmond', 'Newport News'],
    'PA': ['Philadelphia', 'Pittsburgh', 'Allentown', 'Erie', 'Reading']
}

branch_states = np.random.choice(states, size=N_BRANCHES, p=state_weights)
branch_cities = [random.choice(branch_cities_by_state[s]) for s in branch_states]

branch_types  = np.random.choice(
    ['Full Service', 'Drive-Through', 'In-Store', 'Corporate'],
    size=N_BRANCHES, p=[0.55, 0.25, 0.15, 0.05]
)

# Target deposits vary by branch type and city tier
def branch_deposit_target(b_type):
    targets = {
        'Full Service': np.random.uniform(18_000_000, 45_000_000),
        'Drive-Through': np.random.uniform(8_000_000, 18_000_000),
        'In-Store': np.random.uniform(5_000_000, 12_000_000),
        'Corporate': np.random.uniform(50_000_000, 120_000_000),
    }
    return round(targets[b_type], 2)

branches_df = pd.DataFrame({
    'branch_id':              branch_ids,
    'branch_name':            [f'ACB {city} - {branch_ids[i]}' for i, city in enumerate(branch_cities)],
    'city':                   branch_cities,
    'state':                  branch_states,
    'region':                 [regions[s] for s in branch_states],
    'branch_type':            branch_types,
    'num_employees':          np.random.randint(8, 45, size=N_BRANCHES),
    'open_year':              np.random.randint(1995, 2023, size=N_BRANCHES),
    'monthly_deposit_target': [branch_deposit_target(b) for b in branch_types],
    'is_active':              np.random.choice([1, 0], size=N_BRANCHES, p=[0.97, 0.03])
})

branches_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_branches.csv'), index=False)
print(f"  -> acb_branches.csv saved ({len(branches_df):,} rows)")


# ============================================================
# DATASET 3 — TRANSACTIONS
# ============================================================
print("\n[3/7] Generating Transaction Data... (this takes a moment)")

txn_types = ['Deposit', 'Withdrawal', 'Transfer', 'Bill Payment',
             'POS Purchase', 'ATM Withdrawal', 'Wire Transfer', 'Direct Deposit']
txn_type_weights = [0.18, 0.12, 0.15, 0.13, 0.22, 0.10, 0.05, 0.05]

channels = ['Branch', 'ATM', 'Mobile App', 'Online Banking', 'Telephone']
channel_weights = [0.20, 0.15, 0.38, 0.22, 0.05]

# Pull from customer list (only active customers)
active_customers = customers_df[customers_df['is_active'] == 1]['customer_id'].tolist()
active_branches  = branches_df[branches_df['is_active'] == 1]['branch_id'].tolist()

txn_ids    = [f'ACB-TXN{str(i).zfill(8)}' for i in range(1, N_TRANSACTIONS + 1)]
txn_dates  = [random_date(START_DATE, END_DATE) for _ in range(N_TRANSACTIONS)]
txn_cust   = np.random.choice(active_customers, size=N_TRANSACTIONS)
txn_branch = np.random.choice(active_branches, size=N_TRANSACTIONS)
txn_type   = np.random.choice(txn_types, size=N_TRANSACTIONS, p=txn_type_weights)
txn_chan   = np.random.choice(channels, size=N_TRANSACTIONS, p=channel_weights)

# Amount depends on transaction type — realistic distribution
def txn_amount(t_type):
    amt_map = {
        'Deposit':         abs(np.random.lognormal(6.5, 1.2)),
        'Withdrawal':      abs(np.random.lognormal(5.0, 0.8)),
        'Transfer':        abs(np.random.lognormal(6.8, 1.4)),
        'Bill Payment':    abs(np.random.lognormal(5.5, 0.6)),
        'POS Purchase':    abs(np.random.lognormal(4.2, 0.9)),
        'ATM Withdrawal':  abs(np.random.choice([40, 60, 80, 100, 200, 300, 500])),
        'Wire Transfer':   abs(np.random.lognormal(9.0, 1.5)),
        'Direct Deposit':  abs(np.random.lognormal(7.8, 0.5)),
    }
    return round(amt_map[t_type], 2)

txn_amounts = [txn_amount(t) for t in txn_type]

# Fraud flags — ~0.4% of transactions are flagged
# Fraud more common in wire transfers and large deposits (realistic)
fraud_prob = []
for t, a in zip(txn_type, txn_amounts):
    if t == 'Wire Transfer' and a > 10000:
        fraud_prob.append(0.035)
    elif t == 'Transfer' and a > 5000:
        fraud_prob.append(0.018)
    elif a > 50000:
        fraud_prob.append(0.025)
    else:
        fraud_prob.append(0.003)

is_fraud = [1 if random.random() < p else 0 for p in fraud_prob]

# Status — most completed, some pending/reversed (realistic)
statuses = np.random.choice(
    ['Completed', 'Pending', 'Reversed', 'Failed'],
    size=N_TRANSACTIONS,
    p=[0.92, 0.04, 0.025, 0.015]
)

transactions_df = pd.DataFrame({
    'transaction_id':   txn_ids,
    'customer_id':      txn_cust,
    'branch_id':        txn_branch,
    'transaction_date': [d.strftime('%Y-%m-%d') for d in txn_dates],
    'transaction_type': txn_type,
    'channel':          txn_chan,
    'amount':           txn_amounts,
    'status':           statuses,
    'is_fraud_flag':    is_fraud,
    'currency':         'USD',  # ACB is US-only for now
})

# Add some nulls on channel (not always captured for older records)
transactions_df = add_missing_values(transactions_df, ['channel'], pct=0.03)
transactions_df = add_duplicates(transactions_df, n=25)

transactions_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_transactions.csv'), index=False)
print(f"  -> acb_transactions.csv saved ({len(transactions_df):,} rows)")


# ============================================================
# DATASET 4 — LOANS
# ============================================================
print("\n[4/7] Generating Loan Data...")

loan_types = ['Personal Loan', 'Auto Loan', 'Mortgage', 'Home Equity Loan',
              'Student Loan', 'Small Business Loan']
loan_type_weights = [0.25, 0.22, 0.28, 0.10, 0.08, 0.07]

loan_ids = [f'ACB-LN{str(i).zfill(7)}' for i in range(1, N_LOANS + 1)]
loan_cust = np.random.choice(active_customers, size=N_LOANS)
loan_type_col = np.random.choice(loan_types, size=N_LOANS, p=loan_type_weights)

# Loan amount by type
def loan_amount(l_type):
    ranges = {
        'Personal Loan':        (2000, 35000),
        'Auto Loan':            (8000, 55000),
        'Mortgage':             (120000, 650000),
        'Home Equity Loan':     (15000, 120000),
        'Student Loan':         (5000, 80000),
        'Small Business Loan':  (25000, 250000),
    }
    lo, hi = ranges[l_type]
    return round(random.uniform(lo, hi), 2)

# Interest rate by loan type + market period (rates rose in 2022-2023)
def interest_rate(l_type, orig_date):
    base_rates = {
        'Personal Loan':        (0.08, 0.22),
        'Auto Loan':            (0.045, 0.14),
        'Mortgage':             (0.03, 0.075),
        'Home Equity Loan':     (0.055, 0.12),
        'Student Loan':         (0.04, 0.09),
        'Small Business Loan':  (0.065, 0.18),
    }
    lo, hi = base_rates[l_type]
    rate = random.uniform(lo, hi)
    # Rate environment uplift post-2022
    if orig_date >= datetime(2022, 6, 1):
        rate = min(rate * 1.35, hi + 0.02)
    return round(rate, 4)

loan_orig_dates = [random_date(datetime(2019, 1, 1), END_DATE) for _ in range(N_LOANS)]
loan_amounts    = [loan_amount(t) for t in loan_type_col]
loan_rates      = [interest_rate(t, d) for t, d in zip(loan_type_col, loan_orig_dates)]
loan_terms_mo   = [random.choice([12, 24, 36, 48, 60, 84, 120, 180, 240, 360])
                   for _ in range(N_LOANS)]

# Outstanding balance = roughly % of original still owed
outstanding_pct = [random.uniform(0.05, 0.98) for _ in range(N_LOANS)]
outstanding_bal = [round(a * p, 2) for a, p in zip(loan_amounts, outstanding_pct)]

# Loan status — performance depends on risk tier (pulled via customer lookup)
# Simplified: assign probabilistically
loan_status_opts = ['Current', '30-59 DPD', '60-89 DPD', '90+ DPD', 'Default', 'Paid Off', 'Written Off']

def loan_status_prob():
    # Rough distribution matching a healthy but stressed portfolio
    return np.random.choice(
        loan_status_opts,
        p=[0.72, 0.06, 0.04, 0.04, 0.03, 0.09, 0.02]
    )

loan_statuses   = [loan_status_prob() for _ in range(N_LOANS)]
days_past_due   = []
for status in loan_statuses:
    if status == 'Current' or status == 'Paid Off' or status == 'Written Off':
        days_past_due.append(0)
    elif status == '30-59 DPD':
        days_past_due.append(random.randint(30, 59))
    elif status == '60-89 DPD':
        days_past_due.append(random.randint(60, 89))
    elif status == '90+ DPD':
        days_past_due.append(random.randint(90, 180))
    else:  # Default
        days_past_due.append(random.randint(120, 365))

loans_df = pd.DataFrame({
    'loan_id':              loan_ids,
    'customer_id':          loan_cust,
    'loan_type':            loan_type_col,
    'origination_date':     [d.strftime('%Y-%m-%d') for d in loan_orig_dates],
    'loan_amount':          loan_amounts,
    'outstanding_balance':  outstanding_bal,
    'interest_rate':        loan_rates,
    'term_months':          loan_terms_mo,
    'loan_status':          loan_statuses,
    'days_past_due':        days_past_due,
    'is_npl':               [1 if s in ['90+ DPD', 'Default', 'Written Off'] else 0
                             for s in loan_statuses],
    'branch_originated':    np.random.choice(active_branches, size=N_LOANS),
})

loans_df = add_missing_values(loans_df, ['interest_rate', 'term_months'], pct=0.015)
loans_df = add_duplicates(loans_df, n=18)

loans_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_loans.csv'), index=False)
print(f"  -> acb_loans.csv saved ({len(loans_df):,} rows)")


# ============================================================
# DATASET 5 — CREDIT CARDS
# ============================================================
print("\n[5/7] Generating Credit Card Data...")

cc_ids    = [f'ACB-CC{str(i).zfill(7)}' for i in range(1, N_CREDIT_CARDS + 1)]
cc_cust   = np.random.choice(active_customers, size=N_CREDIT_CARDS)

card_types = ['Standard', 'Rewards', 'Platinum', 'Business', 'Secured']
card_type_weights = [0.30, 0.28, 0.18, 0.14, 0.10]

# Credit limit by card type
def cc_limit(card_type):
    limit_ranges = {
        'Standard':  (500, 8000),
        'Rewards':   (2000, 15000),
        'Platinum':  (5000, 30000),
        'Business':  (10000, 75000),
        'Secured':   (200, 2500),
    }
    lo, hi = limit_ranges[card_type]
    return round(random.randint(lo, hi) / 100) * 100  # Round to nearest $100

cc_card_type = np.random.choice(card_types, size=N_CREDIT_CARDS, p=card_type_weights)
cc_limits    = [cc_limit(t) for t in cc_card_type]

# Utilization: real distribution skews low but has a fat right tail
cc_utilization = np.random.beta(1.5, 4, size=N_CREDIT_CARDS)
cc_utilization = np.clip(cc_utilization, 0, 1.0)
cc_balances    = [round(u * l, 2) for u, l in zip(cc_utilization, cc_limits)]

cc_open_dates = [random_date(datetime(2017, 1, 1), END_DATE) for _ in range(N_CREDIT_CARDS)]

# Payment status
cc_status = np.random.choice(
    ['Current', '30 DPD', '60 DPD', '90+ DPD', 'Charge-Off', 'Closed'],
    size=N_CREDIT_CARDS,
    p=[0.75, 0.07, 0.05, 0.04, 0.02, 0.07]
)

# Reward points (only for Rewards and Platinum cards)
reward_pts = []
for ct in cc_card_type:
    if ct in ['Rewards', 'Platinum']:
        reward_pts.append(random.randint(0, 150000))
    else:
        reward_pts.append(0)

credit_cards_df = pd.DataFrame({
    'card_id':            cc_ids,
    'customer_id':        cc_cust,
    'card_type':          cc_card_type,
    'credit_limit':       cc_limits,
    'current_balance':    cc_balances,
    'utilization_rate':   [round(u, 4) for u in cc_utilization],
    'open_date':          [d.strftime('%Y-%m-%d') for d in cc_open_dates],
    'payment_status':     cc_status,
    'reward_points':      reward_pts,
    'is_active':          np.random.choice([1, 0], size=N_CREDIT_CARDS, p=[0.91, 0.09]),
    'annual_fee':         [{'Standard': 0, 'Rewards': 95, 'Platinum': 195,
                            'Business': 150, 'Secured': 35}[t] for t in cc_card_type],
})

credit_cards_df = add_missing_values(credit_cards_df, ['utilization_rate'], pct=0.02)
credit_cards_df = add_duplicates(credit_cards_df, n=20)

credit_cards_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_credit_cards.csv'), index=False)
print(f"  -> acb_credit_cards.csv saved ({len(credit_cards_df):,} rows)")


# ============================================================
# DATASET 6 — BRANCH PERFORMANCE (Monthly Metrics)
# ============================================================
print("\n[6/7] Generating Branch Performance Data...")

# Generate monthly performance records per branch (last 24 months)
months = pd.date_range(start='2024-04-01', end='2026-03-31', freq='MS')
branch_perf_rows = []

for _, branch_row in branches_df.iterrows():
    for month in months:
        deposit_target = branch_row['monthly_deposit_target']
        n_emp = branch_row['num_employees']
        b_type = branch_row['branch_type']

        # Actual deposits fluctuate around target with seasonal patterns
        seasonal_factor = 1 + 0.08 * np.sin(2 * np.pi * month.month / 12)
        actual_deposits = round(deposit_target * seasonal_factor *
                                np.random.uniform(0.82, 1.18), 2)

        # New accounts opened
        new_accounts = max(0, int(np.random.normal(
            {'Full Service': 28, 'Drive-Through': 12, 'In-Store': 9, 'Corporate': 5}[b_type],
            5
        )))

        # Loan originations count
        loan_originations = max(0, int(np.random.normal(
            {'Full Service': 35, 'Drive-Through': 15, 'In-Store': 8, 'Corporate': 20}[b_type],
            8
        )))

        # Operating expenses
        base_opex = n_emp * random.uniform(4500, 6500)
        opex = round(base_opex * np.random.uniform(0.92, 1.10), 2)

        # Customer satisfaction (CSAT) — 1 to 5 scale, tends toward 3.8-4.5
        csat = round(np.random.normal(4.1, 0.4), 1)
        csat = max(1.0, min(5.0, csat))

        # SLA adherence
        sla_rate = round(np.random.beta(18, 2), 4)  # Skews toward high adherence

        branch_perf_rows.append({
            'branch_id':            branch_row['branch_id'],
            'report_month':         month.strftime('%Y-%m'),
            'actual_deposits':      actual_deposits,
            'deposit_target':       round(deposit_target, 2),
            'deposit_attainment':   round(actual_deposits / deposit_target, 4),
            'new_accounts_opened':  new_accounts,
            'loan_originations':    loan_originations,
            'operating_expenses':   opex,
            'num_employees':        n_emp,
            'revenue_per_employee': round((actual_deposits * 0.032) / n_emp, 2),
            'csat_score':           csat,
            'sla_adherence_rate':   sla_rate,
            'state':                branch_row['state'],
            'region':               branch_row['region'],
        })

branch_perf_df = pd.DataFrame(branch_perf_rows)
branch_perf_df = add_missing_values(branch_perf_df, ['csat_score'], pct=0.03)

branch_perf_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_branch_performance.csv'), index=False)
print(f"  -> acb_branch_performance.csv saved ({len(branch_perf_df):,} rows)")


# ============================================================
# DATASET 7 — RISK & FRAUD FLAGS
# ============================================================
print("\n[7/7] Generating Risk & Fraud Flags Data...")

# Pull all flagged transactions + add some customer-level risk flags
fraud_txns = transactions_df[transactions_df['is_fraud_flag'] == 1].copy()

fraud_categories = [
    'Account Takeover', 'Card Not Present', 'Identity Theft',
    'Synthetic Identity', 'Transaction Velocity', 'Unusual Geography',
    'Money Laundering Suspicion', 'Structuring'
]

fraud_cat_weights = [0.20, 0.25, 0.15, 0.10, 0.18, 0.07, 0.03, 0.02]

risk_flags_df = pd.DataFrame({
    'flag_id':         [f'ACB-RF{str(i).zfill(7)}' for i in range(1, len(fraud_txns) + 1)],
    'transaction_id':  fraud_txns['transaction_id'].values,
    'customer_id':     fraud_txns['customer_id'].values,
    'flag_date':       fraud_txns['transaction_date'].values,
    'flag_category':   np.random.choice(fraud_categories, size=len(fraud_txns),
                                        p=fraud_cat_weights),
    'flagged_amount':  fraud_txns['amount'].values,
    'investigation_status': np.random.choice(
        ['Under Review', 'Confirmed Fraud', 'False Positive', 'Pending'],
        size=len(fraud_txns),
        p=[0.30, 0.40, 0.22, 0.08]
    ),
    'loss_amount':     [round(a * random.uniform(0.0, 0.95), 2)
                        if random.random() < 0.45 else 0.0
                        for a in fraud_txns['amount'].values],
    'detection_method': np.random.choice(
        ['Rules Engine', 'ML Model', 'Manual Review', 'Customer Report'],
        size=len(fraud_txns),
        p=[0.45, 0.30, 0.15, 0.10]
    ),
})

risk_flags_df.to_csv(os.path.join(OUTPUT_DIR, 'acb_risk_fraud_flags.csv'), index=False)
print(f"  -> acb_risk_fraud_flags.csv saved ({len(risk_flags_df):,} rows)")


# ============================================================
# SUMMARY
# ============================================================
print("\n" + "="*60)
print("Dataset Generation Complete")
print("="*60)

datasets = {
    'acb_customers.csv':          len(customers_df),
    'acb_branches.csv':           len(branches_df),
    'acb_transactions.csv':       len(transactions_df),
    'acb_loans.csv':              len(loans_df),
    'acb_credit_cards.csv':       len(credit_cards_df),
    'acb_branch_performance.csv': len(branch_perf_df),
    'acb_risk_fraud_flags.csv':   len(risk_flags_df),
}

print(f"\n{'File':<35} {'Rows':>10}")
print("-"*47)
for fname, rows in datasets.items():
    print(f"  {fname:<33} {rows:>10,}")

total = sum(datasets.values())
print("-"*47)
print(f"  {'TOTAL RECORDS':<33} {total:>10,}")
print(f"\nAll files saved to: {os.path.abspath(OUTPUT_DIR)}")
print("\nNext step: Run data_cleaning.py or open the SQL schema scripts.")
