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
- **KPI row:** Portfolio Value, Avg Loan Size, Avg Interest Rate, Concentration (Top 10%) — all four locked to the current/latest year (`Year_loan = Max(Year_loan)`), each with a YoY delta and "vs [X] Prior Year" comparison line. Originally the headline value on each card was unfiltered (reflecting whatever years were selected) while the delta was always single-year — fixed so every card consistently represents the latest year, regardless of selections
- **Top 10 Customers by Loan Amount:** grouped by `customer_id & fullname` combined, not `fullname` alone — the dataset has multiple distinct customers sharing the same generated name (e.g. several different "Aaron Cruz" records), which was silently merging different people's loan totals together on the original build
- **Loan Amount by City and Account Type:** breakdown across the two dimensions, `Invalid` used for blank/null account types, consistent with the Transaction Flow sheet's null-handling convention
- **Monthly Originations — YoY Overlay:** current year vs. prior year, aligned by month
- **Risk-Value Segmentation (scatter):** customers bucketed into Prime / Watch / Sub-prime by fixed credit-score bands (≥740 / 670–739 / <670 — standard industry convention, not a statistical threshold like the Transaction sheet's z-scores)
- **Avg Interest Rate by Credit Score Band:** tests whether riskier customers are actually priced with higher rates — see finding below
- **Watchlist — Sub-Prime, High Exposure:** filtered to Sub-prime only using set analysis directly inside each expression (`{<credit_score={"<670"}>}`) — this row-filtering approach worked reliably, unlike the calculated-dimension + Suppress-When-Null method attempted on the Transaction sheet's Outlier Accounts table

**Notable finding, not a bug:** Avg Interest Rate by Credit Score Band came out nearly flat and backwards (Prime 8.58%, Sub-prime 8.46%, Watch 8.51%) — Sub-prime should carry the highest rate in real-world risk-based pricing. Most likely explanation: `interest_rate` was generated independently of `credit_score` in this synthetic dataset, so there's no real pricing relationship to find. Documented as a data limitation rather than something to force a "fix" for.

**Open issue:** Risk-Value Segmentation scatter renders almost every bubble red (Sub-prime) across the full 300–800 credit score range, including bubbles that should read Watch/Prime around 700–750 — the color-by-expression logic needs a second look against the `Class(credit_score, 50)` bucketing driving the chart.

## Key Calculation — Account Segmentation (Z-Score)

Accounts are segmented by how far their 7-day transaction volume sits from the population mean, in standard deviations:

```
z = (account's 7-day Sum(transaction_amount) − mean across all accounts) / stddev across all accounts
```

Thresholds: `z > 3` = Outlier, `z > 2` = Elevated, else Normal. Implemented via a shared variable (`vAccountZScore`) referencing `TOTAL Aggr(Sum(...), account_id)` for the population mean/stddev, so the same fixed yardstick applies to every account.

**Caveat:** this is a statistical proxy, not a fraud determination — the schema has no fraud/status field. It flags accounts worth a closer look, nothing more.

## Key Calculation — Loans KPI Year-Locking

All four Loans sheet KPIs are explicitly filtered to the current/latest year:

```
Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
```

rather than left to respond to whatever's currently selected on the sheet. This was a deliberate fix — the original build had each KPI's headline value unfiltered (so a 2-year selection would show a 2-year combined total) while the YoY delta beneath it was always a strict single-year comparison, producing numbers that visibly didn't reconcile with each other. Every KPI on this sheet, including Concentration (Top 10%), now follows the same rule for consistency, even though Concentration could arguably be treated as a longer-term structural metric rather than a per-year one — validated against SQL at ~20% for the current year (see `SQL_Validation_Queries.md`).

## Key Calculation — Credit Risk Segmentation (Prime / Watch / Sub-prime)

Unlike the Transaction sheet's statistical z-score segmentation, Loans risk segmentation uses **fixed, industry-standard credit score bands**, not a calculation relative to the dataset's own distribution:

```
Prime:      credit_score >= 740
Watch:      670 <= credit_score < 740
Sub-prime:  credit_score < 670
```

These thresholds are a standard convention, not derived from this data.

## Design Notes
- Palette: ink navy `#0F1E33` panels, paper `#EDEAE1` background, gold `#B8863B` accent, teal `#2E6F62` / crimson `#9C3B3B` for segment coloring
- Typeface: Georgia (serif) for headers, monospace for tabular/numeric values
- QlikView has no native heatmap, sparkline, or Pareto-cumulative-% object — these were built as workarounds (background-color-shaded tables, mini line charts, combo charts with Full Accumulate) rather than native chart types

## Validation Scripts

SQL queries used to sanity-check QlikView expressions against the raw source data before trusting them on the dashboard. Full queries in `SQL_Validation_Queries.md` (also split into individual files under `/validation/`).

| Script | Sheet | Purpose |
|---|---|---|
| `validate_date_ranges.sql` | Transactions | Confirms the 7-day set analysis windows are correctly bounded and non-overlapping |
| `validate_weekly_totals.sql` | Transactions | This week vs last week `Sum(transaction_amount)`, matches Total Volume KPI |
| `validate_kpis.sql` | Transactions | Core 3 KPIs + both Velocity Outliers variants (legacy count-based, current volume-based) |
| `validate_merchant_pareto.sql` | Transactions | Top 10 merchant concentration + a corrected TRUE cumulative % (original was per-merchant % of total, not cumulative) |
| `validate_weekly_volume_day_of_week.sql` | Transactions | Current vs prior week by weekday; caught the same 1-day overlap bug found in the KPI expressions |
| `validate_card_type_and_top_accounts.sql` | Transactions | Null-safe card type grouping; Top 5 accounts ranked by volume, not count |
| `validate_loans_kpis.sql` | Loans | Portfolio Value / Avg Loan Size / Avg Interest Rate / Concentration, year-filtered to match the QlikView cards |
| `validate_top_customers_by_loan.sql` | Loans | Top 10 customers by loan amount + an automated name-collision check |

## Screenshots

Dashboard screenshots live in `/screenshots/`, one per sheet/object, for anyone reviewing the repo without opening QlikView Desktop.

- `screenshots/transaction-flow-overview.png`
- `screenshots/loans-overview.png`
- `screenshots/merchant-pareto.png`
- `screenshots/account-volume-segments.png`
- `screenshots/loans-kpi-row.png`
- `screenshots/top-10-customers-by-loan.png`
- `screenshots/risk-value-segmentation.png`
- `screenshots/watchlist-sub-prime.png`

*(Update this list as screenshots are added — filenames should describe the object, not just "screenshot1.png", so they're identifiable without opening each one.)*

## Automation — Reload & Error Checking

Notes on how the QlikView document reload is scheduled and what's checked automatically to catch data/load issues before anyone views the dashboard.

- **Reload schedule:** *(document the actual schedule here — e.g., QlikView Publisher task, Windows Task Scheduler + batch reload, frequency)*
- **Error checking on reload:** *(document what's checked — e.g., row count sanity checks after load, `TRACE` statements in the script logging table row counts, alerts on synthetic key detection, script-level validation that `Max(date_transaction)`/`Max(date_loan)` return real recent dates rather than null/stale)*
- **Known fragile points to monitor:**
  - `transaction_datetime` parsing — confirm new source data doesn't reintroduce the null-parsing issue noted above
  - Synthetic keys — reload log should be checked for any new synthetic key warnings, since the current model was specifically built to avoid a circular reference; a new field addition could reintroduce one
  - Row counts per table, compared against the prior reload, to catch a failed/partial data pull early
  - Name collisions — re-run `validate_top_customers_by_loan.sql`'s collision check after any reload; new synthetic customer records could introduce new shared names

*(Fill in the actual reload mechanism and checks once set up — this section is a placeholder structure to complete.)*

## Status
Transaction Flow sheet: built and functional, layout/alignment complete. Loans sheet: all KPIs and core charts built and validated against SQL; one open visual bug (Risk-Value Segmentation scatter coloring) and one data-limitation finding (flat/backwards risk pricing) documented above.
