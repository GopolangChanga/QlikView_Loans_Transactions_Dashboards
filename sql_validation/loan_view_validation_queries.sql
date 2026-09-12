# BankSphere — SQL Validation Queries (Loans Sheet)

All SQL used to validate the Loans sheet's QlikView expressions against the raw source data. Run the query for whichever object you're checking.

Source: [Synthetic Banking Dataset (Kaggle)](https://www.kaggle.com/datasets/akrambelha/synthetic-banking-dataset-csv-sql-sqlite)

---

## Loans Sheet

### Portfolio Value, Avg Loan Size, Avg Interest Rate (current year, matching QlikView's year-locked KPIs)
*(Original had no year filter at all — fixed to match the QlikView cards, which are locked to `Max(Year_loan)`.)*

```sql
WITH bounds AS (
    SELECT MAX(YEAR([start_date])) AS max_year FROM [Bank].[dbo].[loans]
)
SELECT
    SUM(L.[loan_amount])     AS [Portfolio Value],
    AVG(L.[loan_amount])     AS [Average Loan Size],
    AVG(L.[interest_rate])   AS [Average Interest Rate]
FROM [Bank].[dbo].[loans] L
CROSS JOIN bounds b
WHERE YEAR(L.[start_date]) = b.max_year;
```

### Prior Year versions (for validating the "VS ... Prior Year" comparison lines)

```sql
WITH bounds AS (
    SELECT MAX(YEAR([start_date])) AS max_year FROM [Bank].[dbo].[loans]
)
SELECT
    SUM(L.[loan_amount])     AS [Prior Year Portfolio Value],
    AVG(L.[loan_amount])     AS [Prior Year Average Loan Size],
    AVG(L.[interest_rate])   AS [Prior Year Average Interest Rate]
FROM [Bank].[dbo].[loans] L
CROSS JOIN bounds b
WHERE YEAR(L.[start_date]) = b.max_year - 1;
```

### Concentration (Top 10%) — current year

```sql
WITH bounds AS (
    SELECT MAX(YEAR([start_date])) AS max_year FROM [Bank].[dbo].[loans]
),
customer_totals AS (
    SELECT customer_id, SUM(loan_amount) AS total_loan
    FROM [Bank].[dbo].[loans]
    CROSS JOIN bounds
    WHERE YEAR(start_date) = bounds.max_year
    GROUP BY customer_id
),
threshold AS (
    SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY total_loan) OVER () AS p90
    FROM customer_totals
)
SELECT SUM(CASE WHEN total_loan >= p90 THEN total_loan ELSE 0 END) / SUM(total_loan) AS concentration_pct
FROM customer_totals, threshold;
```
*(Validated: SQL returns 0.199072 ≈ 20%, matching the QlikView card exactly.)*

### Top 10 Customers by Loan Amount
*(Groups by `customer_id` AND `Full_Name` together — correctly avoids the name-collision bug found earlier, where multiple distinct customers shared a generated name.)*

```sql
SELECT TOP 10
     C.[Full_Name]
    ,SUM(L.[loan_amount]) AS [Portfolio_Value]
FROM [Bank].[dbo].[loans] AS L
LEFT JOIN (
    SELECT [customer_id], CONCAT([first_name], ' ', [last_name]) AS [Full_Name]
    FROM [Bank].[dbo].[customers]
) AS C ON L.[customer_id] = C.[customer_id]
GROUP BY L.[customer_id], C.[Full_Name]
ORDER BY [Portfolio_Value] DESC;
```

### Name-Collision Check (automated version of the manual spot-check)
Flags any display name shared by more than one `customer_id` — run this after any reload to catch new collisions before they silently merge different customers on a chart.

```sql
SELECT
    C.[Full_Name],
    COUNT(DISTINCT L.[customer_id]) AS distinct_customers_behind_this_name
FROM [Bank].[dbo].[loans] AS L
LEFT JOIN (
    SELECT [customer_id], CONCAT([first_name], ' ', [last_name]) AS [Full_Name]
    FROM [Bank].[dbo].[customers]
) AS C ON L.[customer_id] = C.[customer_id]
GROUP BY C.[Full_Name]
HAVING COUNT(DISTINCT L.[customer_id]) > 1
ORDER BY distinct_customers_behind_this_name DESC;
```
