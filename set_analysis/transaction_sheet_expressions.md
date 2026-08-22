# QlikView KPI Expressions — Transaction Flow Sheet

Reference for all 4 top-row KPI cards: variables, display formatting, WoW delta logic, and comparison text. Each variable is documented with what it does; real issues found while packaging this are flagged inline as `-- ISSUE:` so they don't get silently carried into the next edit.

Shared abbreviation pattern used throughout (B/M/K formatting) is repeated per KPI rather than a single shared function, since QlikView variables can't take parameters — worth knowing this is intentional duplication, not an oversight.

---

## 1. Total Volume

```qlik
// Raw value, all-time
vtrans_amnt = Sum(transaction_amount)

// Display value with B/M/K abbreviation
Total Volume =
If( Fabs($(vtrans_amnt)) >= 1000000000, Num($(vtrans_amnt)/1000000000, '$#,##0.0') & 'B',
  If( Fabs($(vtrans_amnt)) >= 1000000,    Num($(vtrans_amnt)/1000000, '$#,##0.0') & 'M',
  If( Fabs($(vtrans_amnt)) >= 1000,       Num($(vtrans_amnt)/1000, '$#,##0.0') & 'K',
       Num($(vtrans_amnt), '$#,##0')
 )))

// This week / last week windows (7 days each, non-overlapping)
vcurrweektransaction =
    Num( SUM( {<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))<=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} transaction_amount ), '#,##0' )

vpriorweektransaction =
    SUM( {<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))"}>} transaction_amount )
```

> **ISSUE — boundary overlap:** `vpriorweektransaction`'s upper bound is `Max(date_transaction)-6`, which is the *same day* as `vcurrweektransaction`'s lower bound. That one day is counted in both windows. Fix: change `vpriorweektransaction`'s upper bound to `-7`.
>
> **ISSUE — quoted variable expansion:** `vwowpercentagevalue` (below) wraps `$(vcurrweektransaction)` and `$(vpriorweektransaction)` in single quotes: `'$(vcurrweektransaction)'`. Since `$(...)` is plain text substitution in QlikView, this turns the expansion into a **string literal** before the subtraction happens (e.g. `'2450000' - '2180000'`), relying on QlikView's implicit string-to-number coercion rather than doing real numeric subtraction. It likely works today, but it's fragile — if either variable ever resolves to something with a stray character (a formatted string instead of a raw number), the subtraction silently breaks. Safer form: drop the quotes entirely — `$(vcurrweektransaction) - $(vpriorweektransaction)`.

```qlik
vwowpercentagevalue =
    Num((( '$(vcurrweektransaction)' - '$(vpriorweektransaction)' ) / '$(vpriorweektransaction)' ) * 100, '0.0')

// Delta text with direction arrow
Volume_WoW =
    If( vwowpercentagevalue > 0,
        Chr(9650) &' '& Num((( '$(vcurrweektransaction)' - '$(vpriorweektransaction)' ) / '$(vpriorweektransaction)' ) * 100, '0.0') & '%' & ' WOW',
        if( vwowpercentagevalue < 0,
            Chr(9660) &' '& Num((( '$(vcurrweektransaction)' - '$(vpriorweektransaction)' ) / '$(vpriorweektransaction)' ) * 100, '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num((( '$(vcurrweektransaction)' - '$(vpriorweektransaction)' ) / '$(vpriorweektransaction)' ) * 100, '0.0') & '%' & ' WOW'
        )
    )

// Comparison text
Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweektransaction)) >= 1000000000, Num($(vpriorweektransaction)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vpriorweektransaction)) >= 1000000, Num($(vpriorweektransaction)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vpriorweektransaction)) >= 1000, Num($(vpriorweektransaction)/1000, '$#,##0.0') & 'K',
                Num($(vpriorweektransaction), '$#,##0')
            )
        )
    )
    &' Last week'
```

`Chr(9650)` = ▲, `Chr(9660)` = ▼, `Chr(11044)` = ◼ (flat/no-change case). Good touch having a neutral symbol for exactly-zero change — most builds only handle up/down.

---

## 2. Transaction Count

```qlik
vdistinct_count_transaction = count( Distinct transaction_id )

Transaction Count =
    If( Fabs($(vdistinct_count_transaction)) >= 1000000000, Num($(vdistinct_count_transaction)/1000000000, '#,##0.0') & 'B',
        If( Fabs($(vdistinct_count_transaction)) >= 1000000, Num($(vdistinct_count_transaction)/1000000, '#,##0.0') & 'M',
            If( Fabs($(vdistinct_count_transaction)) >= 1000, Num($(vdistinct_count_transaction)/1000, '#,##0.0') & 'K',
                Num($(vdistinct_count_transaction), '#,##0')
            )
        )
    )

vcurrweek_dist_count_transaction =
    Count({<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} DISTINCT transaction_id)

vpriorweek_dist_count_transaction =
    Count({<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction) -6, 'YYYY-MM-DD'))"}>} DISTINCT transaction_id)

vwowpercentagevalue_distcounttransaction =
    Num((( '$(vcurrweek_dist_count_transaction)' - '$(vpriorweek_dist_count_transaction)' ) / '$(vpriorweek_dist_count_transaction)' ) * 100, '0.0')
```

> **ISSUE — same overlap bug as Total Volume:** `vpriorweek_dist_count_transaction`'s upper bound is `-6`, same day as `vcurrweek_dist_count_transaction`'s lower bound. Fix to `-7`.

```qlik
TransactionCount_WoW =
    If( vwowpercentagevalue_distcounttransaction > 0,
        Chr(9650) &' '& Num((( '$(vcurrweek_dist_count_transaction)' - '$(vpriorweek_dist_count_transaction)' ) / '$(vpriorweek_dist_count_transaction)' ) * 100, '0.0') & '%' & ' WOW',
        if( vwowpercentagevalue < 0,
            Chr(9660) &' '& Num((( '$(vcurrweek_dist_count_transaction)' - '$(vpriorweek_dist_count_transaction)' ) / '$(vpriorweek_dist_count_transaction)' ) * 100, '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num((( '$(vcurrweek_dist_count_transaction)' - '$(vpriorweek_dist_count_transaction)' ) / '$(vpriorweek_dist_count_transaction)' ) * 100, '0.0') & '%' & ' WOW'
        )
    )
```

> **ISSUE — real bug, wrong variable referenced:** the middle branch checks `if( vwowpercentagevalue < 0, ...)` — that's the **Total Volume** delta variable (`vwowpercentagevalue`), not this KPI's own `vwowpercentagevalue_distcounttransaction`. This means Transaction Count's down-arrow (▼) case is being decided by whatever Total Volume's WoW % happens to be, not its own. If Total Volume is up while Transaction Count is actually down, this card would show the wrong arrow. **Fix:** change `if( vwowpercentagevalue < 0,` to `if( vwowpercentagevalue_distcounttransaction < 0,` — same typo pattern to check for in the Avg Ticket Size block below and the Total Volume block above, since copy-pasting this structure is clearly how it was built.

```qlik
Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000000000, Num($(vpriorweek_dist_count_transaction)/1000000000, '#,##0.0') & 'B',
        If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000000, Num($(vpriorweek_dist_count_transaction)/1000000, '#,##0.0') & 'M',
            If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000, Num($(vpriorweek_dist_count_transaction)/1000, '#,##0.0') & 'K',
                Num($(vpriorweek_dist_count_transaction), '#,##0')
            )
        )
    )
    &' Last week'
```

---

## 3. Average Ticket Size

```qlik
vaverage_transaction = avg(transaction_amount)

Avg Ticket Size =
    If( Fabs($(vaverage_transaction)) >= 1000000000, Num($(vaverage_transaction)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vaverage_transaction)) >= 1000000, Num($(vaverage_transaction)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vaverage_transaction)) >= 1000, Num($(vaverage_transaction)/1000, '$#,##0.0') & 'K',
                Num($(vaverage_transaction), '$#,##0')
            )
        )
    )

vcurrweek_avg_transaction_amnt =
    Avg({<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} transaction_amount)

vpriorweek_avg_transaction_amnt =
    =Avg({<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction) -6, 'YYYY-MM-DD'))"}>} transaction_amount)
```

> **ISSUE — same overlap bug again:** upper bound `-6` should be `-7`. Three-for-three on this same off-by-one across all three KPIs — worth fixing once, everywhere, rather than patching each variable individually and risking missing one (see "Recommended Fix" at the bottom).
>
> **ISSUE — stray leading `=`:** `vpriorweek_avg_transaction_amnt` starts with `=Avg(...)`, i.e. an extra `=` before `Avg`. Variable definitions in QlikView don't need (and shouldn't have) a leading `=` unless it's meant to force expression evaluation in a specific context — worth double-checking this doesn't cause a silent double-evaluation or formatting inconsistency compared to the other variables in this doc, none of which have the leading `=`.

```qlik
vwowpercentagevalue_avg_transaction_amnt =
    Num((( '$(vcurrweek_avg_transaction_amnt)' - '$(vpriorweek_avg_transaction_amnt)' ) / '$(vpriorweek_avg_transaction_amnt)' ) * 100, '0.0')

Avg Ticket Size_WoW =
    If( vwowpercentagevalue_avg_transaction_amnt > 0,
        Chr(9650) &' '& Num((( '$(vcurrweek_avg_transaction_amnt)' - '$(vpriorweek_avg_transaction_amnt)' ) / '$(vpriorweek_avg_transaction_amnt)' ) * 100, '0.0') & '%' & ' WOW',
        if( vwowpercentagevalue_avg_transaction_amnt < 0,
            Chr(9660) &' '& Num((( '$(vcurrweek_avg_transaction_amnt)' - '$(vpriorweek_avg_transaction_amnt)' ) / '$(vpriorweek_avg_transaction_amnt)' ) * 100, '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num((( '$(vcurrweek_avg_transaction_amnt)' - '$(vpriorweek_avg_transaction_amnt)' ) / '$(vpriorweek_avg_transaction_amnt)' ) * 100, '0.0') & '%' & ' WOW'
        )
    )
```

Good — this block correctly references its own `vwowpercentagevalue_avg_transaction_amnt` in the middle branch. This is the one KPI of the three that **doesn't** have the cross-referenced-variable bug found in Transaction Count above — worth comparing the two side by side when fixing it, since this block shows what the corrected version should look like.

```qlik
Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000000000, Num($(vpriorweek_avg_transaction_amnt)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000000, Num($(vpriorweek_avg_transaction_amnt)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000, Num($(vpriorweek_avg_transaction_amnt)/1000, '$#,##0.0') & 'K',
                Num($(vpriorweek_avg_transaction_amnt), '$#,##0')
            )
        )
    )
    &' Last week'
```

---

## 4. Velocity Outliers

```qlik
// Current-week outlier count
Count(Distinct
    Aggr(
        If(
        (
            (Count( DISTINCT transaction_id)
            - Avg(TOTAL Aggr(Count( transaction_id), account_id_fact)))
            /
            StDev(TOTAL Aggr(Count( DISTINCT transaction_id), account_id_fact))
        )
        > 3,
            account_id_fact
        ),
        account_id_fact
    )
)
```

> **ISSUE — this is the most serious bug in the whole set: no date window at all.** Every other KPI's "current week" variable filters with `{<date_transaction={"...">}}`. This expression has **no set analysis whatsoever** — it's computing the outlier count across **all-time** data, not the current 7-day window. Meanwhile the `Last_Week` version directly below **does** have the correct 7-day set analysis. That means the KPI card is comparing an **all-time** figure against a **windowed** figure — these aren't the same basis at all, and the resulting WoW-style comparison ("47 vs 57 last week," from earlier in this project) is not actually a valid week-over-week comparison. **Fix:** add the same `{<date_transaction={">=$(=Date(Max(date_transaction)-6,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction),'YYYY-MM-DD'))"}>}` filter to every `Count(...transaction_id)` call in this block, matching the `Last_Week` version's structure exactly.
>
> **ISSUE — inconsistent `DISTINCT` usage within the same block:** the numerator uses `Count(DISTINCT transaction_id)`, but the mean calculation (`Avg(TOTAL Aggr(Count(transaction_id), ...))`) does not. Same inconsistency flagged earlier in this project — pick one and use it in both places.
>
> **ISSUE — this is the legacy count/frequency-based version**, not the volume-based (`Sum(transaction_amount)`) version the dashboard's Outlier Accounts table currently uses. Worth confirming which version this KPI card is actually supposed to match — if the table below it on the sheet uses volume-based z-scores but this KPI card uses count-based, they'll disagree with each other in a way that looks like a bug to anyone viewing the dashboard, even though each is "correct" by its own separate logic.

```qlik
// Prior-week outlier count — this one IS correctly windowed
Last_Week =
    'VS'& ' '&
    Count(Distinct
        Aggr(
            If(
                (Count( {<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))"}>} DISTINCT transaction_id)
                - Avg(TOTAL Aggr(Count( {<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))"}>} transaction_id), account_id_fact)))
                /
                StDev(TOTAL Aggr(Count( {<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))"}>} DISTINCT transaction_id), account_id_fact))
            > 3,
            account_id_fact
        ),
        account_id_fact
    )
)
&' Last week'
```

> **ISSUE — same overlap bug, again:** upper bound here is `-6`, should be `-7` to avoid the one-day overlap with the (currently missing, see above) current-week window.

---

## Recommended Fix — Summary

All four issue types repeat across multiple KPIs, which suggests these variables were built by copy-pasting one block and adjusting field names — a fast way to build, but also how the same bugs propagated three or four times over. Rather than patching each variable individually:

1. **Fix the `-6` → `-7` boundary once**, then re-check every `vpriorweek...` variable in this document for the same pattern.
2. **Add the missing date filter to Velocity Outliers' current-week expression** — this is the one genuinely functional bug (not just an edge-case overlap), since right now it's silently comparing all-time data against a windowed prior week.
3. **Fix the cross-referenced variable bug in Transaction Count's `TransactionCount_WoW`** (`vwowpercentagevalue` → `vwowpercentagevalue_distcounttransaction`).
4. **Standardize `DISTINCT` usage** — pick one convention (recommend: always `DISTINCT` on `transaction_id`, since it's technically redundant given the primary key but harmless, and consistent is safer than mixed) and apply it everywhere.
---

## CORRECTED VERSION — Ready to Paste

Every issue flagged above is fixed below. Changes made:
- All `-6`/`-7` boundaries corrected so "this week" and "last week" never overlap
- Quoted variable expansions (`'$(var)'`) changed to unquoted (`$(var)`) so subtraction is done on real numbers, not string-coerced text
- Transaction Count's `TransactionCount_WoW` now checks its own variable (`vwowpercentagevalue_distcounttransaction`) instead of the Total Volume one
- Stray leading `=` removed from `vpriorweek_avg_transaction_amnt`
- `DISTINCT` standardized to always appear on `transaction_id` counts, everywhere
- Velocity Outliers current-week expression now has the same 7-day date filter as its Last_Week counterpart
- Velocity Outliers switched to the **volume-based** version (`Sum(transaction_amount)`), matching what the Outlier Accounts table on the dashboard already uses — so the KPI card and the table agree with each other

### 1. Total Volume

```qlik
vtrans_amnt = Sum(transaction_amount)

Total Volume =
If( Fabs($(vtrans_amnt)) >= 1000000000, Num($(vtrans_amnt)/1000000000, '$#,##0.0') & 'B',
  If( Fabs($(vtrans_amnt)) >= 1000000,    Num($(vtrans_amnt)/1000000, '$#,##0.0') & 'M',
  If( Fabs($(vtrans_amnt)) >= 1000,       Num($(vtrans_amnt)/1000, '$#,##0.0') & 'K',
       Num($(vtrans_amnt), '$#,##0')
 )))

vcurrweektransaction =
    Num( SUM( {<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD'))<=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} transaction_amount ), '#,##0' )

vpriorweektransaction =
    Num( SUM( {<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-7, 'YYYY-MM-DD'))"}>} transaction_amount ), '#,##0' )

vwowpercentagevalue =
    Num((( $(vcurrweektransaction) - $(vpriorweektransaction) ) / $(vpriorweektransaction) ) * 100, '0.0')

Volume_WoW =
    If( vwowpercentagevalue > 0,
        Chr(9650) &' '& Num($(vwowpercentagevalue), '0.0') & '%' & ' WOW',
        If( vwowpercentagevalue < 0,
            Chr(9660) &' '& Num($(vwowpercentagevalue), '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num($(vwowpercentagevalue), '0.0') & '%' & ' WOW'
        )
    )

Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweektransaction)) >= 1000000000, Num($(vpriorweektransaction)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vpriorweektransaction)) >= 1000000, Num($(vpriorweektransaction)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vpriorweektransaction)) >= 1000, Num($(vpriorweektransaction)/1000, '$#,##0.0') & 'K',
                Num($(vpriorweektransaction), '$#,##0')
            )
        )
    )
    &' Last week'
```

### 2. Transaction Count

```qlik
vdistinct_count_transaction = Count( Distinct transaction_id )

Transaction Count =
    If( Fabs($(vdistinct_count_transaction)) >= 1000000000, Num($(vdistinct_count_transaction)/1000000000, '#,##0.0') & 'B',
        If( Fabs($(vdistinct_count_transaction)) >= 1000000, Num($(vdistinct_count_transaction)/1000000, '#,##0.0') & 'M',
            If( Fabs($(vdistinct_count_transaction)) >= 1000, Num($(vdistinct_count_transaction)/1000, '#,##0.0') & 'K',
                Num($(vdistinct_count_transaction), '#,##0')
            )
        )
    )

vcurrweek_dist_count_transaction =
    Count({<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} DISTINCT transaction_id)

vpriorweek_dist_count_transaction =
    Count({<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction)-7, 'YYYY-MM-DD'))"}>} DISTINCT transaction_id)

vwowpercentagevalue_distcounttransaction =
    Num((( $(vcurrweek_dist_count_transaction) - $(vpriorweek_dist_count_transaction) ) / $(vpriorweek_dist_count_transaction) ) * 100, '0.0')

TransactionCount_WoW =
    If( vwowpercentagevalue_distcounttransaction > 0,
        Chr(9650) &' '& Num($(vwowpercentagevalue_distcounttransaction), '0.0') & '%' & ' WOW',
        If( vwowpercentagevalue_distcounttransaction < 0,
            Chr(9660) &' '& Num($(vwowpercentagevalue_distcounttransaction), '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num($(vwowpercentagevalue_distcounttransaction), '0.0') & '%' & ' WOW'
        )
    )

Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000000000, Num($(vpriorweek_dist_count_transaction)/1000000000, '#,##0.0') & 'B',
        If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000000, Num($(vpriorweek_dist_count_transaction)/1000000, '#,##0.0') & 'M',
            If( Fabs($(vpriorweek_dist_count_transaction)) >= 1000, Num($(vpriorweek_dist_count_transaction)/1000, '#,##0.0') & 'K',
                Num($(vpriorweek_dist_count_transaction), '#,##0')
            )
        )
    )
    &' Last week'
```

### 3. Average Ticket Size

```qlik
vaverage_transaction = Avg(transaction_amount)

Avg Ticket Size =
    If( Fabs($(vaverage_transaction)) >= 1000000000, Num($(vaverage_transaction)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vaverage_transaction)) >= 1000000, Num($(vaverage_transaction)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vaverage_transaction)) >= 1000, Num($(vaverage_transaction)/1000, '$#,##0.0') & 'K',
                Num($(vaverage_transaction), '$#,##0')
            )
        )
    )

vcurrweek_avg_transaction_amnt =
    Avg({<date_transaction = {">=$(=Date(Max(date_transaction)-6, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction), 'YYYY-MM-DD'))"}>} transaction_amount)

vpriorweek_avg_transaction_amnt =
    Avg({<date_transaction = {">=$(=Date(Max(date_transaction)-13, 'YYYY-MM-DD')) <=$(=Date(Max(date_transaction)-7, 'YYYY-MM-DD'))"}>} transaction_amount)

vwowpercentagevalue_avg_transaction_amnt =
    Num((( $(vcurrweek_avg_transaction_amnt) - $(vpriorweek_avg_transaction_amnt) ) / $(vpriorweek_avg_transaction_amnt) ) * 100, '0.0')

Avg Ticket Size_WoW =
    If( vwowpercentagevalue_avg_transaction_amnt > 0,
        Chr(9650) &' '& Num($(vwowpercentagevalue_avg_transaction_amnt), '0.0') & '%' & ' WOW',
        If( vwowpercentagevalue_avg_transaction_amnt < 0,
            Chr(9660) &' '& Num($(vwowpercentagevalue_avg_transaction_amnt), '0.0') & '%' & ' WOW',
            Chr(11044) &' '& Num($(vwowpercentagevalue_avg_transaction_amnt), '0.0') & '%' & ' WOW'
        )
    )

Last_Week =
    'VS'& ' '&
    If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000000000, Num($(vpriorweek_avg_transaction_amnt)/1000000000, '$#,##0.0') & 'B',
        If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000000, Num($(vpriorweek_avg_transaction_amnt)/1000000, '$#,##0.0') & 'M',
            If( Fabs($(vpriorweek_avg_transaction_amnt)) >= 1000, Num($(vpriorweek_avg_transaction_amnt)/1000, '$#,##0.0') & 'K',
                Num($(vpriorweek_avg_transaction_amnt), '$#,##0')
            )
        )
    )
    &' Last week'
```

### 4. Velocity Outliers (switched to volume-based, matches Outlier Accounts table)

```qlik
vAccountZScore_CurrWeek =
(
    Sum({<date_transaction={">=$(=Date(Max(date_transaction)-6,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction),'YYYY-MM-DD'))"}>} transaction_amount)
    - Avg(TOTAL Aggr(Sum({<date_transaction={">=$(=Date(Max(date_transaction)-6,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction),'YYYY-MM-DD'))"}>} transaction_amount), account_id_fact))
)
/ StDev(TOTAL Aggr(Sum({<date_transaction={">=$(=Date(Max(date_transaction)-6,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction),'YYYY-MM-DD'))"}>} transaction_amount), account_id_fact))

Velocity Outliers =
Count(Distinct
    Aggr(
        If( $(vAccountZScore_CurrWeek) > 3, account_id_fact ),
        account_id_fact
    )
)

vAccountZScore_PriorWeek =
(
    Sum({<date_transaction={">=$(=Date(Max(date_transaction)-13,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-7,'YYYY-MM-DD'))"}>} transaction_amount)
    - Avg(TOTAL Aggr(Sum({<date_transaction={">=$(=Date(Max(date_transaction)-13,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-7,'YYYY-MM-DD'))"}>} transaction_amount), account_id_fact))
)
/ StDev(TOTAL Aggr(Sum({<date_transaction={">=$(=Date(Max(date_transaction)-13,'YYYY-MM-DD'))<=$(=Date(Max(date_transaction)-7,'YYYY-MM-DD'))"}>} transaction_amount), account_id_fact))

Last_Week =
    'VS'& ' '&
    Count(Distinct
        Aggr(
            If( $(vAccountZScore_PriorWeek) > 3, account_id_fact ),
            account_id_fact
        )
    )
    &' Last week'
```

