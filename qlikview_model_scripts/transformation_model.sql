// ============================================================================
// TRANSFORM LAYER - Qlik Sense / QlikView Load Scripts
// ============================================================================
// Purpose : Clean, enrich and standardise data from Extract QVDs
// Layer   : Transform (T)
// Source  : $(vQVD_E_Directory)\*.qvd
// Target  : $(vQVD_T_Directory)\*.qvd
//
// Prerequisites:
//   - Variable vQVD_E_Directory must point to the Extract QVD folder
//   - Variable vQVD_T_Directory must point to the Transform QVD folder
//   - Extract layer must have been successfully executed
//
// Transformations applied:
//   - Capitalize + Trim on string fields
//   - Date formatting (YYYY-MM-DD)
//   - Derived flags (e.g. _is_high_value_client)
//   - Derived status fields (e.g. account_status)
//   - Concatenated full name
//   - Time extraction from datetime
// ============================================================================


// ----------------------------------------------------------------------------
// ACCOUNTS
// Source : Extract accounts.qvd
// Changes:
//   - Rename balance_usd → account_balance
//   - Capitalize + Trim account_type
//   - Flag high-value clients (balance >= 100 000)
//   - Derive account_status (Overdrawn / Active)
//   - Format open_date as YYYY-MM-DD
// ----------------------------------------------------------------------------
accounts:
LOAD
    account_id,
    customer_id,
    Capitalize(Trim(account_type))                          as account_type,
    balance_usd                                             as account_balance,
    If(balance_usd >= 100000, 1, 0)                         as _is_high_value_client,
    If(balance_usd < 0, 'Overdrawn', 'Active')              as account_status,
    Date(open_date, 'YYYY-MM-DD')                           as account_open_date
FROM [$(vQVD_E_Directory)\accounts.qvd] (qvd);

STORE accounts INTO [$(vQVD_T_Directory)\accounts.qvd] (qvd);
DROP TABLE accounts;


// ----------------------------------------------------------------------------
// BRANCHES
// Source : Extract branches.qvd
// Changes:
//   - Capitalize + Trim branch_name, city, country
//   - Handle missing manager_name → 'Invalid'
// ----------------------------------------------------------------------------
branches:
LOAD
    branch_id,
    Trim(Capitalize(branch_name))                           as branch_name,
    Trim(Capitalize(city))                                  as city,
    Trim(Capitalize(country))                               as country,
    If(Len(Trim(manager_name)) = 0, 'Invalid',
       Trim(Capitalize(manager_name)))                      as manager_name
FROM [$(vQVD_E_Directory)\branches.qvd] (qvd);

STORE branches INTO [$(vQVD_T_Directory)\branches.qvd] (qvd);
DROP TABLE branches;


// ----------------------------------------------------------------------------
// CARDS
// Source : Extract cards.qvd
// Changes:
//   - Capitalize + Trim card_type
//   - Format expiration_date as YYYY-MM-DD
// ----------------------------------------------------------------------------
cards:
LOAD
    card_id,
    account_id,
    Trim(Capitalize(card_type))                             as card_type,
    Date(expiration_date, 'YYYY-MM-DD')                     as card_expiration_date
FROM [$(vQVD_E_Directory)\cards.qvd] (qvd);

STORE cards INTO [$(vQVD_T_Directory)\cards.qvd] (qvd);
DROP TABLE cards;


// ----------------------------------------------------------------------------
// CUSTOMERS
// Source : Extract customers.qvd
// Changes:
//   - Capitalize + Trim city and email
//   - Format created_at as YYYY-MM-DD → account_created_date
//   - Concatenate first_name + last_name → fullname
// ----------------------------------------------------------------------------
customers:
LOAD
    customer_id,
    Trim(Capitalize(city))                                  as city,
    Date(created_at, 'YYYY-MM-DD')                          as account_created_date,
    credit_score,
    Trim(Capitalize(email))                                 as email_address,
    Trim(Capitalize(first_name)) & ' ' &
    Trim(Capitalize(last_name))                             as fullname
FROM [$(vQVD_E_Directory)\customers.qvd] (qvd);

STORE customers INTO [$(vQVD_T_Directory)\customers.qvd] (qvd);
DROP TABLE customers;


// ----------------------------------------------------------------------------
// MERCHANTS
// Source : Extract merchants.qvd
// Changes:
//   - Capitalize + Trim city and merchant_name
// ----------------------------------------------------------------------------
merchants:
LOAD
    merchant_id,
    Trim(Capitalize(city))                                  as city,
    Trim(Capitalize(merchant_name))                         as merchant_name
FROM [$(vQVD_E_Directory)\merchants.qvd] (qvd);

STORE merchants INTO [$(vQVD_T_Directory)\merchants.qvd] (qvd);
DROP TABLE merchants;


// ----------------------------------------------------------------------------
// FACT_LOANS
// Source : Extract loans.qvd
// Changes:
//   - Format start_date as YYYY-MM-DD → loan_start_date
//   - Table renamed to fact_loans for clarity
// ----------------------------------------------------------------------------
fact_loans:
LOAD
    loan_id,
    customer_id,
    interest_rate,
    loan_amount,
    Date(start_date, 'YYYY-MM-DD')                          as loan_start_date
FROM [$(vQVD_E_Directory)\loans.qvd] (qvd);

STORE fact_loans INTO [$(vQVD_T_Directory)\Fact_loans.qvd] (qvd);
DROP TABLE fact_loans;


// ----------------------------------------------------------------------------
// FACT_TRANSACTIONS
// Source : Extract transactions.qvd
// Changes:
//   - Rename amount_usd → transaction_amount
//   - Format transaction_date as date only
//   - Keep original datetime
//   - Extract time component
// ----------------------------------------------------------------------------
fact_transactions:
LOAD
    account_id,
    amount_usd                                              as transaction_amount,
    merchant_id,
    Date(transaction_date, 'YYYY-MM-DD')                    as transaction_date,
    transaction_date                                        as transaction_datetime,
    Time(transaction_date)                                  as transaction_time,
    transaction_id
FROM [$(vQVD_E_Directory)\transactions.qvd] (qvd);

STORE fact_transactions INTO [$(vQVD_T_Directory)\Fact_transactions.qvd] (qvd);
DROP TABLE fact_transactions;


// ============================================================================
// End of Transform Layer
// ============================================================================
