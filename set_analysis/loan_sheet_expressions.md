# BankSphere — QlikView Scripts by Object (Loans Sheet)

All QlikView variables and expressions for the Loans sheet, organized by object, in final corrected form. Where a bug was found and fixed during the build, the original issue is noted so the reasoning isn't lost.

---

## Loans Sheet

### 1. Portfolio Value KPI (current year, locked to Max(Year_loan))

```qlik
vloan_amnt = Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)

KPI =
If( Fabs($(vloan_amnt)) >= 1000000000, Num($(vloan_amnt)/1000000000, '$#,##0.0') & 'B',
  If( Fabs($(vloan_amnt)) >= 1000000,    Num($(vloan_amnt)/1000000, '$#,##0.0') & 'M',
  If( Fabs($(vloan_amnt)) >= 1000,       Num($(vloan_amnt)/1000, '$#,##0.0') & 'K',
       Num($(vloan_amnt), '$#,##0')
 )))

vcurryearloan = Num(Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount), '#,##0')

vprioryearloan = Sum({< date_loan ={">=$(= YearStart( Max (date_loan ), -1) ) <=$(= AddYears( Max( date_loan ), -1 ) )"}>} loan_amount)

vyoypercentagevalue = Num((( $(vcurryearloan) - $(vprioryearloan) ) / $(vprioryearloan) ) * 100, '0.0')

Volume_YoY =
If( vyoypercentagevalue > 0,
    Chr(9650) &' '& Num($(vyoypercentagevalue), '0.0') & '%' & ' YOY',
    If( vyoypercentagevalue < 0,
        Chr(9660) &' '& Num($(vyoypercentagevalue), '0.0') & '%' & ' YOY',
        Chr(11044) &' '& Num($(vyoypercentagevalue), '0.0') & '%' & ' YOY'
    )
)

Last_Year =
'VS'& ' '&
If( Fabs($(vprioryearloan)) >= 1000000000, Num($(vprioryearloan)/1000000000, '$#,##0.0') & 'B',
    If( Fabs($(vprioryearloan)) >= 1000000, Num($(vprioryearloan)/1000000, '$#,##0.0') & 'M',
        If( Fabs($(vprioryearloan)) >= 1000, Num($(vprioryearloan)/1000, '$#,##0.0') & 'K',
            Num($(vprioryearloan), '$#,##0')
        )
    )
)
&' Prior Year'
```
*Fixed: original `vloan_amnt` had no year filter, while the YoY delta below it did — meant the headline number reflected whatever was currently selected (e.g. a 2-year combined total) while the delta always compared exactly one year vs the prior year, producing numbers that didn't reconcile. Decision made: lock every KPI on this sheet to the current/latest year, not the ambient selection, for consistency.*

### 2. Average Loan Size KPI (same fix pattern)

```qlik
vaverage_loan = Avg({<Year_loan={$(=Max(Year_loan))}>} loan_amount)

KPI =
If( Fabs($(vaverage_loan)) >= 1000000000, Num($(vaverage_loan)/1000000000, '#,##0.0') & 'B',
  If( Fabs($(vaverage_loan)) >= 1000000,    Num($(vaverage_loan)/1000000, '#,##0.0') & 'M',
  If( Fabs($(vaverage_loan)) >= 1000,       Num($(vaverage_loan)/1000, '#,##0.0') & 'K',
       Num($(vaverage_loan), '#,##0')
 )))

vavgcurryearloan = Num(Avg({<Year_loan={$(=Max(Year_loan))}>} loan_amount), '#,##0')

vavgprioryearloan = Avg({< date_loan ={">=$(= YearStart( Max (date_loan ), -1) ) <=$(= AddYears( Max( date_loan ), -1 ) )"}>} loan_amount)

vavgyoypercentagevalue = Num((( $(vavgcurryearloan) - $(vavgprioryearloan) ) / $(vavgprioryearloan) ) * 100, '0.0')
```
*(WoW/delta text and "Prior Year" comparison follow the same pattern as Portfolio Value above.)*

### 3. Average Interest Rate KPI (same fix pattern)

```qlik
vavg_interest_rate = Avg({<Year_loan={$(=Max(Year_loan))}>} interest_rate)

KPI = Num($(vavg_interest_rate), '#,##0.0') & '%'

vavgcurryear_interest_rate = Num(Avg({<Year_loan={$(=Max(Year_loan))}>} interest_rate), '#,##0')

vavgprioryear_interest_rate = Avg({< date_loan ={">=$(= YearStart(Max(date_loan),-1) ) <=$(= AddYears(Max(date_loan), -1))"}>} interest_rate)
```
*Note: displayed with 1 decimal place, which can make current vs prior year look identical (e.g. both "8.5%") even when a real ~6% YoY difference exists underneath — consider 2 decimals if precision matters more than a clean look for this specific KPI.*

### 4. Concentration (Top 10%) KPI — year-filtered version

```qlik
=Num(
  Sum(
    Aggr(
      If(
        Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
        >=
        Fractile(TOTAL Aggr(Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount), customer_id), 0.90),
        Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
      ),
      customer_id
    )
  )
  /
  Sum({<Year_loan={$(=Max(Year_loan))}>} TOTAL loan_amount),
  '#,##0%'
)

vTop10_perc_loan_amnt =
Sum(
    Aggr(
      If(
        Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
        >=
        Fractile(TOTAL Aggr(Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount), customer_id), 0.90),
        Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
      ),
      customer_id
    )
  )

Last_Week =
'Top 10 Customers:'& ' '&
If( Fabs($(vTop10_perc_loan_amnt)) >= 1000000000, Num($(vTop10_perc_loan_amnt)/1000000000, '$#,##0.0') & 'B',
  If( Fabs($(vTop10_perc_loan_amnt)) >= 1000000,    Num($(vTop10_perc_loan_amnt)/1000000, '$#,##0.0') & 'M',
  If( Fabs($(vTop10_perc_loan_amnt)) >= 1000,       Num($(vTop10_perc_loan_amnt)/1000, '$#,##0.0') & 'K',
       Num($(vTop10_perc_loan_amnt), '$#,##0')
 )))
```
*Decision point: whether Concentration should be year-locked (structural consistency with the other 3 KPIs) or reflect the full selection/all-time (arguably more meaningful for a "who are our biggest relationships" question) was discussed — year-locked version chosen and validated against SQL (20% match confirmed).*

### 5. Top 10 Customers by Loan Amount

```
Dimension:  =customer_id & ' — ' & fullname   (guarantees grouping by the real unique key,
            not by name alone — multiple distinct customer_ids sharing a generated
            fullname, e.g. several different "Aaron Cruz" records, was confirmed
            in this dataset)
Label:      =Only(fullname)   (NOTE: found to be tied to Legend display, not the
            axis directly, in this QlikView version — a data-label/text-on-axis
            approach may be needed instead if the axis still shows the combined
            ID+name string)
Expression: =Sum(loan_amount), sorted descending, Top 10
```

### 6. Loan Amount by City and Account Type

```
Dimension 1: customers.city
Dimension 2: account_type
Expression:  =Sum(loan_amount)
```

### 7. Monthly Originations — YoY Overlay

```
Dimension:  Month_loan (both series aligned to the same Jan-Dec axis)
Expression 1 (current year): =Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)
Expression 2 (prior year):   =Sum({< date_loan ={">=$(= YearStart( Max (date_loan ), -1) ) <=$(= AddYears( Max( date_loan ), -1 ) )"}>} loan_amount)
```

### 8. Risk-Value Segmentation (scatter)

```
Dimension:  =Class(credit_score, 50)   (controls how many bubbles appear)
Expression X: =Avg(credit_score)
Expression Y: =Sum(loan_amount)
Bubble size:  =Avg(interest_rate)
Color logic (Prime/Watch/Sub-prime):
  =If(Avg(credit_score) >= 740, RGB(46,111,98),
     If(Avg(credit_score) >= 670, RGB(184,134,59),
        RGB(156,59,59)))
```
*Observed issue: most bubbles across the full 300-800 credit score range render red (Sub-prime), including bubbles that should read Watch/Prime around 700-750 — color-by-expression logic worth re-checking against the Class() bucketing.*

### 9. Average Interest Rate by Credit Score Band (Risk Pricing)

```
Dimension:  =If(Avg(credit_score) >= 740, 'Prime',
               If(Avg(credit_score) >= 670, 'Watch', 'Sub-prime'))
Sort:       =Match(dimension_value, 'Prime','Watch','Sub-prime')  (ascending, forces
            Prime -> Watch -> Sub-prime order regardless of value)
Expression: =Avg(interest_rate)
Background Color: =If(Avg(credit_score) >= 740, RGB(46,111,98),
                      If(Avg(credit_score) >= 670, RGB(184,134,59), RGB(156,59,59)))
```
*Observed finding, not a bug: Prime 8.58%, Sub-prime 8.46%, Watch 8.51% — nearly flat and backwards (Sub-prime should carry the highest rate). Likely means `interest_rate` was generated independently of `credit_score` in this synthetic dataset — worth stating as a data limitation rather than forcing a "fix."*

### 10. Watchlist — Sub-Prime, High Exposure (table)
*(Uses set-analysis filtering directly inside each expression to limit rows to Sub-prime only — this approach worked reliably, unlike the calculated-dimension + Suppress-When-Null method attempted on the Transactions sheet's Outlier Accounts table.)*

```
Loan Amount:   =Sum({<credit_score={"<670"}>} loan_amount)
Interest Rate: =Sum({<credit_score={"<670"}>} interest_rate)
Credit Score:  =Sum({<credit_score={"<670"}>} credit_score)
Segment:       =If(credit_score >= 740, 'Prime',
                   If(credit_score >= 670, 'Watch', 'Sub-prime'))
Text Color (on Segment column, via "+" tree under Expressions/Visual Cues tab):
  =If(Segment = 'Prime', RGB(46,111,98),
     If(Segment = 'Watch', RGB(184,134,59),
        RGB(156,59,59)))
```
