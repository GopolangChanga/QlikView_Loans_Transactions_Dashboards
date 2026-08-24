# QlikView KPI Expressions — Transaction Flow Sheet

Reference for all 4 top-row KPI cards: variables, display formatting, WoW delta logic, and comparison text. 

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

---

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

