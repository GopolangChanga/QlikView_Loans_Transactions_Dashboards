/* ============================================================
   validate_kpis.sql

   Purpose:
   Validates the 4 top-row KPI cards on the Transaction Flow sheet:
   Total Volume, Transaction Count, Avg Ticket Size, Velocity Outliers.

   Compare against QlikView:
     Total Volume        =Sum(amount_usd)
     Transaction Count   =Count(transaction_id)
     Avg Ticket Size     =Avg(amount_usd)
     Velocity Outliers   =Count(Distinct account_id) where z-score > 3
                          (see PART 2 below -- current dashboard uses
                          the VOLUME-based version, not the count-based
                          one; both are included here for reference)

   NOTE: all-time basis (no date window) shown here for the core 3
   KPIs. Re-run with a WHERE clause on transaction_date if you need
   to validate a specific 7-day window instead -- see
   validate_date_ranges.sql for the correct window boundaries.
   ============================================================ */


-- ============================================================
-- PART 1: Core KPI totals (all-time basis)
-- ============================================================
SELECT
      SUM([amount_usd])   AS Total_Volume
     ,COUNT([transaction_id]) AS Transaction_Count
     ,AVG([amount_usd])   AS Average_Ticket_Size
FROM [Bank].[dbo].[transactions];


-- ============================================================
-- PART 2a: Velocity Outliers -- LEGACY, count-based (frequency)
--
-- Flags accounts whose TRANSACTION COUNT is a 3-sigma outlier.
-- NOTE: this was dropped from the live dashboard after discovering
-- most accounts have only 1-2 transactions/week, making count a
-- poor differentiator -- kept here only for historical reference,
-- not what the dashboard currently displays.
-- ============================================================
WITH per_account_counts AS (
    SELECT
        t.account_id,
        COUNT(DISTINCT t.transaction_id) AS txn_count
    FROM [Bank].[dbo].[transactions] t
    GROUP BY t.account_id
),
population_stats AS (
    SELECT
        AVG(CAST(txn_count AS FLOAT)) AS mean_count,
        STDEV(txn_count)              AS stddev_count
    FROM per_account_counts
)
SELECT COUNT(*) AS outlier_account_count_LEGACY_by_frequency
FROM per_account_counts p
CROSS JOIN population_stats s
WHERE (p.txn_count - s.mean_count) / NULLIF(s.stddev_count, 0) > 3;


-- ============================================================
-- PART 2b: Velocity Outliers -- CURRENT, volume-based
--
-- Flags accounts whose 7-DAY DOLLAR VOLUME is a 3-sigma outlier.
-- This is what the "Velocity Outliers" KPI and the "Outlier
-- Accounts -- Elevated Volume" table currently use.
--
-- Compare against QlikView's $(vAccountZScore) > 3 logic.
-- ============================================================
WITH bounds AS (
    SELECT MAX(transaction_date) AS max_date
    FROM [Bank].[dbo].[transactions]
),
per_account_volume AS (
    SELECT
        t.account_id,
        SUM(t.amount_usd) AS total_volume
    FROM [Bank].[dbo].[transactions] t
    CROSS JOIN bounds b
    WHERE t.transaction_date >= DATEADD(day, -6, b.max_date)
      AND t.transaction_date <= b.max_date
    GROUP BY t.account_id
),
population_stats AS (
    SELECT
        AVG(total_volume) AS mean_volume,
        STDEV(total_volume) AS stddev_volume
    FROM per_account_volume
)
SELECT COUNT(*) AS outlier_account_count_CURRENT_by_volume
FROM per_account_volume p
CROSS JOIN population_stats s
WHERE (p.total_volume - s.mean_volume) / NULLIF(s.stddev_volume, 0) > 3;
