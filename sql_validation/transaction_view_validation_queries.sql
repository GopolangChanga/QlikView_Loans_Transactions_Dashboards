/* ================================================================
   BankSphere -- Dashboard Validation Queries (Consolidated)
   ================================================================
   All validation SQL for the Transaction Flow QlikView sheet,
   combined into one file. Each section below was originally a
   separate script (still available individually in /validation/
   if preferred) -- run whichever SELECT statement(s) you need for
   the object you're checking, not the whole file top to bottom,
   since several sections return multiple result sets.

   TABLE OF CONTENTS
   -----------------
   1. Date Range Validation        (window boundaries, no overlap)
   2. Weekly Totals                (Total Volume KPI, this vs last week)
   3. Core KPIs                    (Total Volume, Txn Count, Avg Ticket,
                                     Velocity Outliers -- both variants)
   4. Merchant Pareto               (Top 10 concentration + true cumulative %)
   5. Weekly Volume by Day of Week (current vs prior week, aligned by weekday)
   6. Card Type & Top Accounts     (null handling, volume-based ranking)
   ================================================================ */


/* ================================================================
   SECTION 1: DATE RANGE VALIDATION
   ================================================================
   Confirms the two 7-day windows used throughout the dashboard are
   anchored correctly, exactly 7 days each, and adjacent with NO
   overlapping day.

   Compare against QlikView Text Objects:
     =Date(Max(date_transaction)-6,'YYYY-MM-DD')   -- this_week_start
     =Date(Max(date_transaction),'YYYY-MM-DD')     -- this_week_end
     =Date(Max(date_transaction)-13,'YYYY-MM-DD')  -- last_week_start
     =Date(Max(date_transaction)-7,'YYYY-MM-DD')   -- last_week_end
   Clear all QlikView selections before comparing -- any active
   filter shifts Max(date_transaction) away from SQL's unfiltered MAX().
   ================================================================ */

WITH bounds AS (
    SELECT MAX(transaction_date) AS max_date
    FROM [Bank].[dbo].[transactions]
)
SELECT
    max_date                              AS qlik_max_date_equivalent,
    DATEADD(day, -6, max_date)            AS this_week_start,
    max_date                              AS this_week_end,
    DATEADD(day, -13, max_date)           AS last_week_start,
    DATEADD(day, -7, max_date)            AS last_week_end,
    -- should always return 1 -- confirms the two windows are adjacent
    DATEDIFF(day, DATEADD(day, -7, max_date), DATEADD(day, -6, max_date)) AS should_equal_1
FROM bounds;


/* ================================================================
   SECTION 2: WEEKLY TOTALS
   ================================================================
   Validates Sum(transaction_amount) for this week / last week
   against the Total Volume KPI card and WoW Overlay chart.

   Compare against QlikView:
     This week:  =Sum({<date_transaction={">=$(=Date(Max(date_transaction)-6,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction),'YYYY-MM-DD'))"}>} transaction_amount)
     Last week:  =Sum({<date_transaction={">=$(=Date(Max(date_transaction)-13,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-7,'YYYY-MM-DD'))"}>} transaction_amount)
   ================================================================ */

WITH bounds AS (
    SELECT MAX(transaction_date) AS max_date
    FROM [Bank].[dbo].[transactions]
)
SELECT
    SUM(CASE
            WHEN t.transaction_date >= DATEADD(day, -6, b.max_date)
             AND t.transaction_date <= b.max_date
            THEN t.transaction_amount
        END) AS this_week_total,
    SUM(CASE
            WHEN t.transaction_date >= DATEADD(day, -13, b.max_date)
             AND t.transaction_date <= DATEADD(day, -7, b.max_date)
            THEN t.transaction_amount
        END) AS last_week_total,
    COUNT(CASE
            WHEN t.transaction_date >= DATEADD(day, -6, b.max_date)
             AND t.transaction_date <= b.max_date
            THEN 1
        END) AS this_week_txn_count,
    COUNT(CASE
            WHEN t.transaction_date >= DATEADD(day, -13, b.max_date)
             AND t.transaction_date <= DATEADD(day, -7, b.max_date)
            THEN 1
        END) AS last_week_txn_count
FROM [Bank].[dbo].[transactions] t
CROSS JOIN bounds b;


/* ================================================================
   SECTION 3: CORE KPIs
   ================================================================
   Total Volume, Transaction Count, Avg Ticket Size (all-time), plus
   Velocity Outliers in both variants: legacy count-based (dropped
   from the live dashboard, kept for reference) and current
   volume-based (matches the Outlier Accounts table).
   ================================================================ */

-- 3a. Core KPI totals (all-time basis)
SELECT
      SUM([amount_usd])       AS Total_Volume
     ,COUNT([transaction_id]) AS Transaction_Count
     ,AVG([amount_usd])       AS Average_Ticket_Size
FROM [Bank].[dbo].[transactions];

-- 3b. Velocity Outliers -- LEGACY, count-based (frequency). Dropped
-- from the live dashboard after discovering most accounts only
-- transact 1-2x/week, making count a poor differentiator.
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

-- 3c. Velocity Outliers -- CURRENT, volume-based (7-day window).
-- Compare against QlikView's $(vAccountZScore_CurrWeek) > 3 logic.
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
        AVG(total_volume)   AS mean_volume,
        STDEV(total_volume) AS stddev_volume
    FROM per_account_volume
)
SELECT COUNT(*) AS outlier_account_count_CURRENT_by_volume
FROM per_account_volume p
CROSS JOIN population_stats s
WHERE (p.total_volume - s.mean_volume) / NULLIF(s.stddev_volume, 0) > 3;


/* ================================================================
   SECTION 4: MERCHANT PARETO
   ================================================================
   Top 10 merchants by volume. ISSUE FIXED: the original
   "Cumulative_%" column was actually per-merchant % of total, not
   a true running cumulative total. Both versions included --
   4a matches the original (renamed for honesty), 4b is the real
   cumulative version to compare against QlikView's Full Accumulate line.
   ================================================================ */

-- 4a. Per-merchant % of total (NOT cumulative)
SELECT TOP 10
    M.[merchant_name] AS Merchant,
    SUM(T.[amount_usd]) AS Volume,
    ( SUM(T.[amount_usd]) / (SUM(SUM(T.[amount_usd])) OVER ()) ) * 100 AS Pct_Of_Total_NOT_Cumulative
FROM [Bank].[dbo].[transactions] AS T
LEFT JOIN [Bank].[dbo].[merchants] AS M
    ON T.[merchant_id] = M.[merchant_id]
GROUP BY M.[merchant_name]
ORDER BY SUM(T.[amount_usd]) DESC;

-- 4b. TRUE cumulative % (matches a real Pareto line)
WITH merchant_totals AS (
    SELECT
        M.[merchant_name] AS merchant,
        SUM(T.[amount_usd]) AS volume
    FROM [Bank].[dbo].[transactions] AS T
    LEFT JOIN [Bank].[dbo].[merchants] AS M
        ON T.[merchant_id] = M.[merchant_id]
    GROUP BY M.[merchant_name]
),
ranked AS (
    SELECT
        merchant,
        volume,
        SUM(volume) OVER (ORDER BY volume DESC
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
        SUM(volume) OVER () AS grand_total,
        ROW_NUMBER() OVER (ORDER BY volume DESC) AS rn
    FROM merchant_totals
)
SELECT TOP 10
    merchant,
    volume,
    (running_total / grand_total) * 100 AS cumulative_pct
FROM ranked
ORDER BY rn;


/* ================================================================
   SECTION 5: WEEKLY VOLUME BY DAY OF WEEK
   ================================================================
   Current vs prior week volume, aligned by weekday. ISSUE FIXED:
   original prior-week range ('2025-12-19' to '2025-12-25')
   overlapped current week on Dec 25 -- same one-day overlap bug
   as the KPI set analysis. Prior week corrected to end 2025-12-24.

   NOTE: hardcoded dates match a specific known snapshot (max date
   = 2025-12-31). Regenerate from Section 1 if source data changes.
   ================================================================ */

-- 5a. Current week (2025-12-25 to 2025-12-31)
SELECT
    LEFT(DATENAME(WEEKDAY, T.[Date]), 3) AS day_name,
    T.[Total_Volume]
FROM (
    SELECT
        CAST(transaction_date AS Date) AS [Date],
        SUM([amount_usd]) AS [Total_Volume]
    FROM [Bank].[dbo].[transactions]
    GROUP BY CAST(transaction_date AS Date)
) AS T
WHERE T.[Date] BETWEEN '2025-12-25' AND '2025-12-31'
ORDER BY
    CASE LEFT(DATENAME(WEEKDAY, T.[Date]), 3)
        WHEN 'Mon' THEN 1 WHEN 'Tue' THEN 2 WHEN 'Wed' THEN 3 WHEN 'Thu' THEN 4
        WHEN 'Fri' THEN 5 WHEN 'Sat' THEN 6 WHEN 'Sun' THEN 7
    END;

-- 5b. Prior week -- FIXED, now 2025-12-18 to 2025-12-24 (no overlap)
SELECT
    LEFT(DATENAME(WEEKDAY, T.[Date]), 3) AS day_name,
    T.[Total_Volume]
FROM (
    SELECT
        CAST(transaction_date AS Date) AS [Date],
        SUM([amount_usd]) AS [Total_Volume]
    FROM [Bank].[dbo].[transactions]
    GROUP BY CAST(transaction_date AS Date)
) AS T
WHERE T.[Date] BETWEEN '2025-12-18' AND '2025-12-24'
ORDER BY
    CASE LEFT(DATENAME(WEEKDAY, T.[Date]), 3)
        WHEN 'Mon' THEN 1 WHEN 'Tue' THEN 2 WHEN 'Wed' THEN 3 WHEN 'Thu' THEN 4
        WHEN 'Fri' THEN 5 WHEN 'Sat' THEN 6 WHEN 'Sun' THEN 7
    END;


/* ================================================================
   SECTION 6: CARD TYPE & TOP ACCOUNTS
   ================================================================
   6a: Bank Card Type by Volume, with nulls/blanks relabeled
   "Invalid" (matches QlikView's IsNull()/Len(Trim())=0 check).
   6b: Top 5 Accounts by transaction SIZE (volume), not count --
   corrected after discovering count-based ranking produced ties
   across nearly the whole account population.
   ================================================================ */

-- 6a. Bank Card Type by Volume (null-safe)
SELECT
    [Card Type],
    Volume
FROM (
    SELECT
        CASE
            WHEN C.[card_type] IS NULL OR LTRIM(RTRIM(C.[card_type])) = ''
                THEN 'Invalid'
            ELSE C.[card_type]
        END AS [Card Type],
        SUM(T.[amount_usd]) AS Volume
    FROM [Bank].[dbo].[transactions] AS T
    LEFT JOIN [Bank].[dbo].[accounts] AS A
        ON T.[account_id] = A.[account_id]
    LEFT JOIN [Bank].[dbo].[cards] AS C
        ON A.[account_id] = C.[account_id]
    GROUP BY
        CASE
            WHEN C.[card_type] IS NULL OR LTRIM(RTRIM(C.[card_type])) = ''
                THEN 'Invalid'
            ELSE C.[card_type]
        END
) AS N
ORDER BY Volume DESC;

-- 6b. Top 5 Accounts by Transaction SIZE (volume), current week
SELECT TOP 5
    [account_id] AS Account,
    SUM(amount_usd) AS Volume
FROM (
    SELECT
        *,
        CAST(transaction_date AS Date) AS [Date]
    FROM [Bank].[dbo].[transactions]
) AS T
WHERE T.[Date] BETWEEN '2025-12-25' AND '2025-12-31'
GROUP BY T.[account_id]
ORDER BY SUM(amount_usd) DESC;
