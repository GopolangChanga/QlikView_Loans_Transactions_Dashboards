// ============================================================================
// PRESENTATION LAYER - QlikView Load Scripts
// ============================================================================
// Purpose : Load transformed QVDs into the final data model used by the app
// Layer   : Presentation (P) / Data Model
// Source  : $(vQVD_T_Directory)\*.qvd
//
// Prerequisites:
//   - Variable vQVD_T_Directory must point to the Transform QVD folder
//   - Transform layer must have been successfully executed
//
// Data Model Notes:
//   - Dimensions and facts are loaded with intentional key aliases
//     to create the desired associations (synthetic keys avoided
//     by using distinct key names where needed).
//   - account_id is aliased multiple times to link:
//       • accounts_dim  ↔ fact_transaction   (account_id_fact)
//       • accounts_dim  ↔ cards_dim          (account_id_card)
//   - Date fields are standardised for calendar linking.
// ============================================================================


// ----------------------------------------------------------------------------
// DIMENSION: accounts_dim
// Source : Transform accounts.qvd
// Role   : Account master data + high-value client flag
// ----------------------------------------------------------------------------
accounts_dim:
LOAD
    account_id,
    account_id                                              as account_id_fact,   // Link to fact_transaction
    account_id                                              as account_id_card,   // Link to cards_dim
    account_type,
    account_balance,
    customer_id,
    _is_high_value_client,
    account_status,
    account_open_date
FROM [$(vQVD_T_Directory)\accounts.qvd] (qvd);


// ----------------------------------------------------------------------------
// DIMENSION: cards_dim
// Source : Transform cards.qvd
// Role   : Card master data linked to accounts
// ----------------------------------------------------------------------------
cards_dim:
LOAD
    card_id,
    account_id                                              as account_id_card,   // Link to accounts_dim
    card_type,
    card_expiration_date
FROM [$(vQVD_T_Directory)\cards.qvd] (qvd);


// ----------------------------------------------------------------------------
// DIMENSION: customer_dim
// Source : Transform customers.qvd
// Role   : Customer master data
// ----------------------------------------------------------------------------
customer_dim:
LOAD
    city,
    account_created_date,
    credit_score,
    customer_id,
    email_address,
    fullname
FROM [$(vQVD_T_Directory)\customers.qvd] (qvd);


// ----------------------------------------------------------------------------
// DIMENSION: merchants_dim
// Source : Transform merchants.qvd
// Role   : Merchant master data
// ----------------------------------------------------------------------------
merchants_dim:
LOAD
    merchant_id,
    city                                                    as merchant_city,     // Avoid clash with customer city
    merchant_name
FROM [$(vQVD_T_Directory)\merchants.qvd] (qvd);


// ----------------------------------------------------------------------------
// FACT: fact_loan
// Source : Transform Fact_loans.qvd
// Role   : Loan transactions / balances
// ----------------------------------------------------------------------------
fact_loan:
LOAD
    customer_id,
    interest_rate,
    loan_amount,
    loan_id,
    loan_start_date                                         as date_loan          // Calendar-friendly date key
FROM [$(vQVD_T_Directory)\Fact_loans.qvd] (qvd);


// ----------------------------------------------------------------------------
// FACT: fact_transaction
// Source : Transform Fact_transactions.qvd
// Role   : Transactional fact table
// ----------------------------------------------------------------------------
fact_transaction:
LOAD
    account_id                                              as account_id_fact,   // Link to accounts_dim
    transaction_amount,
    merchant_id,
    Date(Floor(transaction_date), 'YYYY-MM-DD')             as date_transaction,  // Date key for calendar
    transaction_datetime,
    transaction_id
FROM [$(vQVD_T_Directory)\Fact_transactions.qvd] (qvd);


// ============================================================================
// End of Presentation Layer
// ============================================================================
//
// Recommended next steps in the load script:
//   1. Load a Master Calendar linked on date_transaction / date_loan
//   2. Apply Section Access if required
//   3. Drop any temporary fields or tables
// ============================================================================
