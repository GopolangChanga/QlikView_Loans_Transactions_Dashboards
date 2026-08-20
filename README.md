# BankSphere — QlikView Transaction & Loan Analytics

A QlikView dashboard built on a synthetic banking schema (`customers`, `accounts`, `cards`, `merchants`, `loans`, `transactions`, `branches`). Covers loan portfolio and transaction flow analytics.

## Source of Data

Synthetic banking dataset (CSV/SQL/SQLite), Kaggle:
https://www.kaggle.com/datasets/akrambelha/synthetic-banking-dataset-csv-sql-sqlite

All customer, account, card, merchant, loan, and transaction records are synthetic — no real personal or financial data is used in this project.

## Data Model

Source schema is a standard relational banking model — customers can hold multiple accounts and multiple loans independently. See `schema.sql` for full DDL.

**Key relationships:**
- `customers` (1) → `accounts` (many)
- `customers` (1) → `loans` (many)
- `accounts` (1) → `cards` (many)
- `accounts` (1) → `transactions` (many)
- `transactions` (many) → `merchants` (1)

**Calendar handling:** two separate calendar tables (`mastercalendar_loan_dim`, `mastercalendar_transaction_dim`) with uniquely suffixed fields (`_loan` / `_transaction`) to avoid a circular reference — `loans` and `transactions` each need their own date context, and sharing one calendar table created an association loop across `customers`.

**Known schema limitations (not modeled, would need source changes):**
- No loan status/aging (active, closed, delinquent, NPL) — no due-date or payment schedule table
- No loan product type (mortgage, auto, personal, etc.)
- No fraud flag or transaction type (wire, ACH, card) on `transactions`
- `branches` table exists but has no foreign key linking it to any other table — currently unused
- `transaction_datetime` does not reliably parse to a time component across all rows (~99.9% returned null on `Hour()`/`WeekDay()` extraction) — hour-of-day analysis was dropped in favor of day-of-week analysis using the reliable `date_transaction` field instead

## Sheets

### Transaction Flow
- **KPI row:** Total Volume, Transaction Count, Avg Ticket Size, Velocity Outliers — each with a plain-text "vs [X] last week" comparison (no set-analysis-driven sparkline, by design choice)
- **Merchant Concentration (Pareto):** Top 10 merchants by volume, with cumulative % line on secondary axis
- **Volume by Day of Week:** substituted for an hour×day heatmap after the `transaction_datetime` parsing issue above
- **Weekly Volume — WoW Overlay:** current vs. prior 7-day window, aligned by weekday
- **Top 5 Accounts by Transaction Size:** ranked by `Sum(transaction_amount)`, not count — count-based ranking was dropped after discovering most accounts have only 1–2 transactions/week, making count a poor differentiator
- **Account Volume Segments:** all accounts labeled Normal / Elevated / Outlier via a z-score on 7-day transaction volume (not transaction count, for the same reason above)
- **Bank Card Type by Volume:** null/blank `card_type` values are relabeled "Invalid" rather than left blank

### Loans
- Portfolio value, avg loan size, avg interest rate, customer credit score distribution, and a large-loans/credit-score watchlist table

## Key Calculation — Account Segmentation (Z-Score)

Accounts are segmented by how far their 7-day transaction volume sits from the population mean, in standard deviations:

```
z = (account's 7-day Sum(transaction_amount) − mean across all accounts) / stddev across all accounts
```

Thresholds: `z > 3` = Outlier, `z > 2` = Elevated, else Normal. Implemented via a shared variable (`vAccountZScore`) referencing `TOTAL Aggr(Sum(...), account_id)` for the population mean/stddev, so the same fixed yardstick applies to every account.

**Caveat:** this is a statistical proxy, not a fraud determination — the schema has no fraud/status field. It flags accounts worth a closer look, nothing more.

## Design Notes
- Palette: ink navy `#0F1E33` panels, paper `#EDEAE1` background, gold `#B8863B` accent, teal `#2E6F62` / crimson `#9C3B3B` for segment coloring
- Typeface: Georgia (serif) for headers, monospace for tabular/numeric values
- QlikView has no native heatmap, sparkline, or Pareto-cumulative-% object — these were built as workarounds (background-color-shaded tables, mini line charts, combo charts with Full Accumulate) rather than native chart types

## Validation Scripts

SQL queries used to sanity-check QlikView expressions against the raw source data before trusting them on the dashboard (see `/validation/` folder).

| Script | Purpose |
|---|---|
| `validate_weekly_totals.sql` | Confirms `Sum(transaction_amount)` per day matches the QlikView WoW KPI cards |
| `validate_top_accounts.sql` | Top 10 accounts by `Sum(amount_usd)` per week — used to catch the count-vs-volume ranking bug (see Key Calculation notes above) |
| `validate_date_ranges.sql` | Confirms the 7-day set analysis windows (`Max(date)-6` to `Max(date)`, and the prior-week equivalent) return non-overlapping, correct row counts |

*(Add scripts to a `/validation/` folder in this repo as they're written; list them here with a one-line description of what each one checks.)*

## Screenshots

Dashboard screenshots live in `/screenshots/`, one per sheet/object, for anyone reviewing the repo without opening QlikView Desktop.

- `screenshots/transaction-flow-overview.png`
- `screenshots/loans-overview.png`
- `screenshots/merchant-pareto.png`
- `screenshots/account-volume-segments.png`

*(Update this list as screenshots are added — filenames should describe the object, not just "screenshot1.png", so they're identifiable without opening each one.)*

## Automation — Reload & Error Checking

Notes on how the QlikView document reload is scheduled and what's checked automatically to catch data/load issues before anyone views the dashboard.

- **Reload schedule:** *(document the actual schedule here — e.g., QlikView Publisher task, Windows Task Scheduler + batch reload, frequency)*
- **Error checking on reload:** *(document what's checked — e.g., row count sanity checks after load, `TRACE` statements in the script logging table row counts, alerts on synthetic key detection, script-level validation that `Max(date_transaction)` returns a real recent date rather than null/stale)*
- **Known fragile points to monitor:**
  - `transaction_datetime` parsing — confirm new source data doesn't reintroduce the null-parsing issue noted above
  - Synthetic keys — reload log should be checked for any new synthetic key warnings, since the current model was specifically built to avoid a circular reference; a new field addition could reintroduce one
  - Row counts per table, compared against the prior reload, to catch a failed/partial data pull early

*(Fill in the actual reload mechanism and checks once set up — this section is a placeholder structure to complete.)*

## Status
Transaction Flow sheet: built and functional. Loans sheet: KPIs and core charts built. Layout/alignment pass in progress.
