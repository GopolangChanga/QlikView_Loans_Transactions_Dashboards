// ============================================================================
// EXTRACT LAYER - Qlik Sense / QlikView Load Scripts
// ============================================================================
// Purpose : Extract raw data from the Bank SQL database and store as QVDs
// Layer   : Extract (E)
// Source  : Bank.dbo.* tables
// Target  : $(vQVD_E_Directory)\*.qvd
//
// Prerequisites:
//   - Variable vQVD_E_Directory must be defined (e.g. in a separate Config script)
//   - OLE DB / ODBC connection to the Bank database must be established
//
// Naming convention:
//   - Table names match source table names
//   - QVD files keep the same base name as the source table
// ============================================================================


// ----------------------------------------------------------------------------
// ACCOUNTS
// Source table: Bank.dbo.accounts
// ----------------------------------------------------------------------------
accounts:
LOAD
    "account_id",
    "account_type",
    "balance_usd",
    "customer_id",
    "open_date"
;
SQL SELECT
    "account_id",
    "account_type",
    "balance_usd",
    "customer_id",
    "open_date"
FROM Bank.dbo.accounts;

// Store as QVD for downstream Transform layer
STORE accounts INTO [$(vQVD_E_Directory)\accounts.qvd] (qvd);

// Free memory
DROP TABLE accounts;


// ----------------------------------------------------------------------------
// BRANCHES
// Source table: Bank.dbo.branches
// ----------------------------------------------------------------------------
branches:
LOAD
    "branch_id",
    "branch_name",
    city,
    country,
    "manager_name"
;
SQL SELECT
    "branch_id",
    "branch_name",
    city,
    country,
    "manager_name"
FROM Bank.dbo.branches;

STORE branches INTO [$(vQVD_E_Directory)\branches.qvd] (qvd);
DROP TABLE branches;


// ----------------------------------------------------------------------------
// CARDS
// Source table: Bank.dbo.cards
// ----------------------------------------------------------------------------
cards:
LOAD
    "account_id",
    "card_id",
    "card_type",
    "expiration_date"
;
SQL SELECT
    "account_id",
    "card_id",
    "card_type",
    "expiration_date"
FROM Bank.dbo.cards;

STORE cards INTO [$(vQVD_E_Directory)\cards.qvd] (qvd);
DROP TABLE cards;


// ----------------------------------------------------------------------------
// CUSTOMERS
// Source table: Bank.dbo.customers
// ----------------------------------------------------------------------------
customers:
LOAD
    city,
    "created_at",
    "credit_score",
    "customer_id",
    email,
    "first_name",
    "last_name"
;
SQL SELECT
    city,
    "created_at",
    "credit_score",
    "customer_id",
    email,
    "first_name",
    "last_name"
FROM Bank.dbo.customers;

STORE customers INTO [$(vQVD_E_Directory)\customers.qvd] (qvd);
DROP TABLE customers;


// ----------------------------------------------------------------------------
// LOANS
// Source table: Bank.dbo.loans
// ----------------------------------------------------------------------------
loans:
LOAD
    "customer_id",
    "interest_rate",
    "loan_amount",
    "loan_id",
    "start_date"
;
SQL SELECT
    "customer_id",
    "interest_rate",
    "loan_amount",
    "loan_id",
    "start_date"
FROM Bank.dbo.loans;

STORE loans INTO [$(vQVD_E_Directory)\loans.qvd] (qvd);
DROP TABLE loans;


// ----------------------------------------------------------------------------
// MERCHANTS
// Source table: Bank.dbo.merchants
// ----------------------------------------------------------------------------
merchants:
LOAD
    city,
    "merchant_id",
    "merchant_name"
;
SQL SELECT
    city,
    "merchant_id",
    "merchant_name"
FROM Bank.dbo.merchants;

STORE merchants INTO [$(vQVD_E_Directory)\merchants.qvd] (qvd);
DROP TABLE merchants;


// ----------------------------------------------------------------------------
// TRANSACTIONS
// Source table: Bank.dbo.transactions
// ----------------------------------------------------------------------------
transactions:
LOAD
    "account_id",
    "amount_usd",
    "merchant_id",
    "transaction_date",
    "transaction_id"
;
SQL SELECT
    "account_id",
    "amount_usd",
    "merchant_id",
    "transaction_date",
    "transaction_id"
FROM Bank.dbo.transactions;

STORE transactions INTO [$(vQVD_E_Directory)\transactions.qvd] (qvd);
DROP TABLE transactions;


// ============================================================================
// End of Extract Layer
// ============================================================================
