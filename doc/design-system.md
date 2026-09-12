# BankSphere — Dashboard Design System

Design reference for building and extending the Transaction Flow and Loans dashboards in QlikView. Covers color, typography, component anatomy, chart conventions, and known QlikView platform constraints.

---

## 1. Color Palette

| Token | Hex | RGB | Usage |
|---|---|---|---|
| Ink Navy | `#0F1E33` | `RGB(15,30,51)` | Card/panel backgrounds, primary bar fill |
| Paper | `#EDEAE1` | `RGB(237,234,225)` | Sheet background |
| Value White | `#EDEAE1` | `RGB(237,234,225)` | KPI value text (on navy) |
| Label Gray-Blue | `#9FB0C8` | `RGB(159,176,200)` | KPI labels, comparison text, secondary captions |
| Gold | `#B8863B` | `RGB(184,134,59)` | Accent, cumulative-% lines, "Elevated" segment |
| Teal | `#2E6F62` | `RGB(46,111,98)` | Positive delta, "Normal"/"Prime" segment |
| Crimson | `#9C3B3B` | `RGB(156,59,59)` | Negative delta, "Outlier"/"Sub-prime" segment |
| Coral (delta only) | `#E38A8A` | `RGB(227,138,138)` | Down-arrow delta text specifically (lighter than Crimson, reserved for KPI deltas) |
| Green (delta only) | `#7FBF9E` | `RGB(127,191,158)` | Up-arrow delta text specifically |
| Hairline | `#D8D2C2` | `RGB(216,210,194)` | Rule lines, gridlines, table borders |

**Segment color convention (applies everywhere a 3-tier segment appears — risk, velocity, volume):**
- Normal / Prime → Teal `#2E6F62`
- Elevated / Watch → Gold `#B8863B`
- Outlier / Sub-prime → Crimson `#9C3B3B`

**Two different segmentation methods share this same color convention — don't confuse them:**
- **Statistical (Transaction sheet):** z-score relative to the dataset's own mean/stddev (e.g. Velocity Outliers, Account Volume Segments). Thresholds are `z > 2` / `z > 3`, derived from the data itself.
- **Fixed-band (Loans sheet):** industry-standard credit score cutoffs (Prime ≥740, Watch 670–739, Sub-prime <670) — a convention, not something calculated from this dataset's distribution. Same visual treatment, different underlying logic — worth knowing which one a given object uses before trying to "fix" a threshold that isn't actually derived from the data.

**Delta color convention (KPI cards only, not segments):**
- Up → Green `#7FBF9E`
- Down → Coral `#E38A8A`
(Note: Delta colors are intentionally lighter/softer than the Segment colors above — deltas are glanceable status, segments are categorical labels; keeping them visually distinct avoids implying a false relationship between "this went down" and "this account is Sub-prime.")

---

## 2. Typography

| Element | Font | Size (approx) | Weight |
|---|---|---|---|
| Sheet title (e.g. "Transaction Flow Analytics") | Georgia (serif) | 28–32pt | Bold |
| Sub-header / eyebrow (e.g. "Ledger — Vol. IV") | Georgia (serif) | 13–14pt | Regular, gold color |
| KPI label ("TOTAL VOLUME") | Georgia or system serif | 9pt | Regular, uppercase |
| KPI value ("$5.0B") | Monospace (Consolas/SF Mono) | 24–26pt | Bold |
| KPI delta ("▼ -11.7% WOW") | Monospace | 11pt | Regular |
| KPI comparison ("vs $13.5M last week") | Monospace or Georgia | 10–11pt | Regular, Label Gray-Blue |
| Chart/table titles | Georgia (serif) | 14–16pt | Regular |
| Table body text | Monospace | 12–12.5pt | Regular |

**Known QlikView limitation:** letter-spacing (tracking) is not a supported text property on QlikView objects. Uppercase labels will render tighter/denser than the same text does in an HTML mockup — don't chase pixel-perfect tracking, it isn't achievable natively.

---

## 3. KPI Card Anatomy

Every KPI card follows the same fixed structure, top to bottom:

1. **Label** — uppercase, Label Gray-Blue, small
2. **Value** — large, bold, monospace, Value White
3. **Delta** — direction arrow (▲/▼) + percentage + comparison period label (e.g. "WOW"), colored Green/Coral by direction
4. **Comparison line** — plain text, Label Gray-Blue, e.g. "vs $13.5M last week" — **not colored**, since the delta line already carries the judgment; duplicating color here adds no information

**Explicitly excluded from the standard card:** embedded sparklines. Tested and dropped — two QlikView objects glued together to fake one embedded chart drift out of alignment whenever the sheet is resized, and the maintenance cost across multiple KPI cards wasn't worth it. If trend context is needed, use a shared trend chart elsewhere on the sheet instead of per-card sparklines.

**KPI scope rule — lock every card to the same period, don't let it drift with ambient selections.** On the Loans sheet, the headline value on each KPI was originally left unfiltered (so it reflected whatever years happened to be selected), while the delta beneath it always compared a single year vs. the prior year — producing a headline and a delta that silently disagreed with each other the moment more than one year was selected. Fix: every KPI's headline value uses the same year/period filter as its own delta (e.g. `Sum({<Year_loan={$(=Max(Year_loan))}>} loan_amount)`), so the number, the delta, and the comparison line always describe the same period, regardless of what else is selected on the sheet.

Card background: Ink Navy, no border, subtle corner radius if the object type supports it.

---

## 4. Chart Conventions

| Chart type | When to use | Notes |
|---|---|---|
| **Combo (bar + line)** | Pareto/concentration charts | Bar = primary metric (Navy), Line = cumulative % with Full Accumulate, on secondary axis, Gold. Always sort descending by the bar's value first, then apply Top-N limit. |
| **Line** | Trend over time, WoW/YoY overlay | Current period = Navy solid, prior period = Gold dashed. Both series must share the same x-axis categories (e.g. both plotted Mon–Sun) — never a raw rolling date sequence, or the two lines won't align meaningfully. |
| **Bar (plain)** | Day-of-week, category comparisons, ranked Top-N lists | Navy fill. Sort descending unless the dimension has inherent order (e.g. Mon–Sun). |
| **Straight Table** | Detail/drill-in lists (e.g. watchlists) | Segment column background-colored per the Segment convention (Section 1). Sort by the most decision-relevant column, usually descending. |
| **Pivot Table (as heatmap substitute)** | Two-dimension density views (e.g. cohort/vintage) | QlikView has no native heatmap object — simulate via a background-color expression scaled to value magnitude. Tune the color-scale divisor to the real data range; don't ship with placeholder scaling. |

**Title convention:** plain static text via the Caption tab, describing what the chart shows in a few words (e.g. "Merchant Concentration — Pareto"). Never bind the caption to a live unformatted expression — this produces raw floating numbers with no context, which has happened before on this project and should be treated as a bug whenever seen.

---

## 5. Layout & Alignment

- **Grid + snap-to-grid**: always on (Sheet Properties → Layout tab) before placing objects.
- **Build order**: one row at a time, confirmed aligned, before starting the next row. Don't align the whole sheet at once — makes it hard to isolate which object is off.
- **Sizing**: match object width/height by explicit values (Object Properties → Layout tab), not by eye-dragging. This is what caused the KPI card overflow issue earlier in the project.
- **Locking**: once a row is aligned, right-click → Allow Move/Size → uncheck, to prevent accidental drift.
- **Standard sheet row order** (Transactions sheet, as built):
  1. Header (title + source-basis line + as-of/vs line)
  2. Drill breadcrumb / date filter
  3. KPI row (4 cards)
  4. Row 3: Pareto chart + Day-of-Week chart, side by side
  5. Row 4: WoW overlay + (segmentation object, if used)
  6. Detail table, full width
  7. Footnote (schema limitations), full width, small text

- **Standard sheet row order** (Loans sheet, as built):
  1. Header (title + source-basis line) + Year/Quarter/Week drill list box
  2. KPI row (4 cards: Portfolio Value, Avg Loan Size, Avg Interest Rate, Concentration)
  3. Row 3: Loan Amount by City & Account Type + Monthly Originations YoY, side by side
  4. Row 4: Risk-Value Segmentation + Avg Interest Rate by Credit Score Band, side by side
  5. Top 10 Customers by Loan Amount, full width
  6. Watchlist — Sub-Prime, High Exposure (table), full width

---

## 6. Header Conventions

- **Source-basis line**: plain English list of source tables (e.g. "Data: Transactions, Merchants, Accounts") — avoid the `⋈` join-symbol notation; it's precise but unfamiliar to most business viewers and risks rendering as a missing glyph.
- **As-of / comparison-window line**: must be a **dynamic expression**, not static text — e.g. `="As of " & Date(Max(transaction_date),'DD MMM YYYY') & " · vs. " & Date(Max(transaction_date)-7,'DD MMM YYYY')`. A hardcoded date here is a real bug, not a placeholder — it will silently become wrong the moment the data reloads.
- **When this header context earns its place**: dashboards that get shared, exported to PDF, or viewed by people who weren't in the room live. If a sheet is only ever presented live with narration, this context is less critical — but default to including it, since screenshots/exports outlive the session they were taken in.

---

## 7. QlikView Platform Constraints (Reference)

Things this design system deliberately works around, not native chart types:

| Desired visual | Native in QlikView? | Workaround used |
|---|---|---|
| Sparkline in KPI card | No | Dropped — see Section 3 |
| Heatmap | No | Pivot table + background-color expression |
| Pareto cumulative line | Partial | Combo chart, second expression with Full Accumulate + secondary axis |
| Drill-down breadcrumb | Yes (native) | Drill-Down Group + List Box; `GetFieldSelections()` text object for a readable breadcrumb label separate from the functional list box |
| Letter-spaced uppercase text | No | Accepted limitation, not worth fighting |
| Row-level filtering (e.g. "only show Elevated/Outlier") | Yes, via set analysis inside expressions | Calculated dimension + Suppress-When-Null was attempted first (Transaction sheet's Outlier Accounts table) and never worked reliably. **Working alternative, found via the Loans Watchlist table:** put the filter condition directly inside each expression's set analysis instead of on the dimension, e.g. `=Sum({<credit_score={"<670"}>} loan_amount)` — this reliably limits which rows contribute to each expression. Retrofit this pattern onto the Transaction sheet's Outlier Accounts table rather than continuing to debug the calculated-dimension approach. |

---

## 8. Naming Convention for Titles

Object titles should describe **what's actually shown**, updated whenever the underlying logic changes — this project has had titles go stale before (e.g. "Elevated Frequency" survived after the metric was changed from transaction count to transaction volume, until caught and corrected to "Elevated Volume"). When you change what an expression measures, check the title in the same edit.

---

## 9. Grouping Key Caution — Never Group by a Display Name Alone

Found on the Loans sheet's "Top 10 Customers by Loan Amount" chart: grouping by `fullname` silently merged different people's loan totals together, because this dataset has multiple distinct `customer_id`s sharing the same generated name (e.g. several different "Aaron Cruz" records) — confirmed via a `HAVING COUNT(DISTINCT customer_id) > 1` check, which returned dozens of collisions.

**Rule going forward:** any dimension built on a human-readable name (`fullname`, `merchant_name`, etc.) must be checked for uniqueness before trusting it as a grouping key. If collisions exist, group by the real primary key (`customer_id`) combined with the name, e.g. `=customer_id & ' — ' & fullname`, not the name alone — even if the name is what should be *displayed*.

**Known limitation with this fix, still unresolved:** attempting to show a clean name-only label (via a `Label` override set to `=Only(fullname)`) while keeping `customer_id` in the grouping dimension did not work as expected in this QlikView version — the Label setting turned out to be tied to Legend display, not the axis text, and unchecking Legend disabled Label entirely rather than revealing a separate axis-label control. As of this writing, the chart displays the full `customer_id — fullname` string on the axis rather than a clean name; a data-label / text-on-axis approach was proposed as the next thing to try but not yet confirmed working.
