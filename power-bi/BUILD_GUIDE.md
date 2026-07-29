# MakeMyTrip Power BI — Build Guide

A four-page report you can build in one sitting. Every visual below lists the exact fields to drop in each well, so you can work down the page without stopping to decide.

Open `Dashboard_Mockup.html` alongside this — it shows what each page should look like when you're done, with the real numbers already in it.

---

## Before you start: what the data actually says

Worth knowing up front, because two of these will otherwise look like bugs in your report.

**Payments only exist for Confirmed, Completed and Refunded bookings.** Pending and Cancelled bookings never paid. So `SUM(Payments[PaymentAmount])` = ₹2.50 Cr while `SUM(Bookings[TotalPrice])` = ₹3.18 Cr. Both are correct; they answer different questions. Headline the net figure (₹2.15 Cr, after ₹35.0 L of refunds) and keep booking value as a separate "basket value" metric.

**2026 stops on 20 July.** Any full-year comparison will show 2026 falling off a cliff. Use the YTD measures for year-on-year, or filter to complete quarters.

**One payment per booking, no orphan records.** The referential integrity is clean, so relationships won't throw errors.

---

## Step 1 — Load

Home → Get Data → Excel workbook → `MakeMyTrip_PowerBI_DataModel.xlsx` → tick all 15 sheets → **Transform Data** (not Load — check types first).

In Power Query, confirm:

| Column | Should be |
|---|---|
| `Bookings[BookingDateTime]` | Date/Time |
| `Bookings[TotalPrice]` | Decimal Number |
| `Payments[PaymentAmount]` | Decimal Number |
| `Payments[PaymentDate]` | Date |
| `Users[RegistrationDate]` | Date |
| `Reviews[Rating]` | Whole Number |
| All `*ID` columns | Whole Number |

Then delete the `Users[Password]` column — it's a masked placeholder and has no business being in a report. Right-click → Remove.

Close & Apply.

---

## Step 2 — Relationships

Model view. Power BI will auto-detect most of these; check every one for correct cardinality and direction rather than trusting it.

| From | Column | To | Column | Cardinality | Active |
|---|---|---|---|---|---|
| Bookings | UserID | Users | UserID | Many→1 | Yes |
| FlightBookings | BookingID | Bookings | BookingID | Many→1 | Yes |
| FlightBookings | FlightID | Flights | FlightID | Many→1 | Yes |
| HotelBookings | BookingID | Bookings | BookingID | Many→1 | Yes |
| HotelBookings | HotelID | Hotels | HotelID | Many→1 | Yes |
| BusBookings | BookingID | Bookings | BookingID | Many→1 | Yes |
| BusBookings | BusID | Buses | BusID | Many→1 | Yes |
| TrainBookings | BookingID | Bookings | BookingID | Many→1 | Yes |
| TrainBookings | TrainID | Trains | TrainID | Many→1 | Yes |
| CarRentalBookings | BookingID | Bookings | BookingID | Many→1 | Yes |
| CarRentalBookings | CarRentalID | CarRentals | CarRentalID | Many→1 | Yes |
| Payments | BookingID | Bookings | BookingID | Many→1 | Yes |
| DiscountCoupons | BookingID | Bookings | BookingID | Many→1 | Yes |
| Reviews | BookingID | Bookings | BookingID | Many→1 | Yes |
| Reviews | UserID | Users | UserID | Many→1 | **No** |
| DateTable | Date | Bookings | BookingDate | 1→Many | Yes |

Cross-filter direction: **Single** on all of them.

Two things that trip people up here:

**Reviews→Users must stay inactive.** Reviews already reaches Users through Bookings. Power BI allows one active path between any two tables, so it'll grey this one out automatically. Leave it. You only need it if you write a measure counting reviews by user independently of bookings, and then you'd wrap it in `USERELATIONSHIP()`.

**Do not connect DateTable to Payments or Reviews.** It's tempting — both have their own date columns. But Payments already reaches DateTable via Bookings, and adding a direct link creates two paths, which Power BI will reject as ambiguous. Since payment date is the same day as booking date in 98% of rows (and one day later in the rest), filtering payments through the booking date costs you nothing. Same for reviews.

---

## Step 3 — Columns, calendar, measures

Open `DAX_Measures.txt` and work through it in order:

1. **Section 0 first** — the DateTable, then `Bookings[BookingDate]`, then the sort and band columns. The date relationship in Step 2 won't work until `BookingDate` exists.
2. Create an empty table called `_Measures` (Modeling → New Table → type `_Measures = {BLANK()}`, then hide the resulting column). Every measure goes here.
3. Paste Sections 1–9. About 60 measures. You won't use them all on the canvas — the extras are there so you can answer questions during a demo without editing the model.

Set formatting as you go: currency measures to `₹ #,0` with 0 decimals, rate measures to Percentage with 1 decimal. Doing this once on the measure saves doing it on every visual.

---

## Step 4 — Theme

View → Themes → Customize current theme.

| Slot | Hex | Used for |
|---|---|---|
| Colour 1 | `#E8453C` | Primary — revenue, headline series |
| Colour 2 | `#123A5F` | Secondary — bookings, volume |
| Colour 3 | `#1F9C8C` | Positive / completed |
| Colour 4 | `#E8A33D` | Warning / pending |
| Colour 5 | `#8B5E9C` | Fifth category |
| Colour 6 | `#6B7A8C` | Neutral / other |

Text: Segoe UI. Page background `#F2F4F7`, visual backgrounds white with a 1px `#E1E5EB` border and 4px rounded corners. Turn off visual shadows — they date the report.

Canvas size 1280×720 (16:9) on every page.

---

## Page 1 — Executive Overview

The page someone looks at for eight seconds.

**Header band** (rectangle shape, `#123A5F`, full width, 70px tall) with a text box: "MakeMyTrip — Performance Overview" in white, 24pt semibold. Right-align a text box showing the data window: "Jan 2024 – Jul 2026".

**KPI row** — five Card visuals across the top, equal width.

| Card | Field | Note |
|---|---|---|
| Net Revenue | `[Net Revenue]` | Should read ₹2.15 Cr |
| Total Bookings | `[Total Bookings]` | 900 |
| Active Users | `[Active Users]` | 284 |
| Avg Rating | `[Avg Rating]` | 4.07 |
| Failed Booking Rate | `[Failed Booking Rate]` | 19.2% — apply `[Cancellation Colour]` |

**Revenue and bookings trend** — Line and clustered column chart, left two-thirds.
- X axis: `DateTable[Year Quarter]`
- Column y-axis: `[Total Bookings]`
- Line y-axis: `[Net Revenue]`
- Title: use the `[Title — Revenue Trend]` measure via fx

Filter this visual to exclude 2026 Q3 (Visual filters → `Year Quarter` → is not `2026 Q3`), otherwise the partial quarter reads as a crash.

**Revenue by service** — Donut chart, right third.
- Legend: `Bookings[ServiceType]`
- Values: `[Net Revenue]`
- Detail labels: Category, percent of total

**Status funnel** — Stacked bar, bottom left.
- Y axis: `Bookings[ServiceType]`
- X axis: `[Total Bookings]`
- Legend: `Bookings[Status]`

**Slicers** — bottom strip: `DateTable[Year]` (tile style), `Bookings[ServiceType]` (dropdown), `Bookings[Status]` (dropdown). Edit interactions so slicers don't filter the header text boxes.

---

## Page 2 — Service Performance

Where the actual analysis lives.

**Revenue vs volume scatter** — top left. This is the visual that earns the page.
- X axis: `[Total Bookings]`
- Y axis: `[Revenue per Booking]`
- Size: `[Net Revenue]`
- Legend / details: `Bookings[ServiceType]`

Hotels sit alone in the top-right quadrant; car rentals bottom-left. That separation is your headline finding.

**Top airlines** — Clustered bar, top right.
- Y axis: `Flights[Airline]`
- X axis: `[Net Revenue]`
- Sort descending, Top N filter = 8

**Top hotel cities** — Clustered bar, middle right.
- Y axis: `Hotels[Location]`
- X axis: `[Net Revenue]`
- Top N = 8

**Failure rate by service** — Line and stacked column, bottom left.
- X axis: `Bookings[ServiceType]`
- Column: `[Cancelled Bookings]`, `[Refunded Bookings]`
- Line: `[Failed Booking Rate]` on secondary axis

**Service detail table** — bottom right. Matrix visual.
- Rows: `Bookings[ServiceType]`
- Values: `[Total Bookings]`, `[Net Revenue]`, `[Revenue per Booking]`, `[Avg Rating]`, `[Failed Booking Rate]`, `[Revenue Share of Total]`
- Conditional formatting: data bars on `[Net Revenue]`, red-green background on `[Failed Booking Rate]` (reverse the scale — high is bad)

---

## Page 3 — Customers and Retention

**Cards row** — `[Repeat Rate]`, `[Bookings per Active User]`, `[Avg Days To First Booking]`, `[Customer Lifetime Value]`, `[Activation Rate]`.

**Registration cohorts** — Column chart.
- X axis: `Users[Registration Cohort]` (sorted by `Registration Cohort Sort`)
- Y axis: `[Total Users]`
- Second series: `[Active Users]`

**Booking value distribution** — Column chart.
- X axis: `Bookings[Price Band]`
- Y axis: `[Total Bookings]`
- Tooltip: add `[Booking Value]` and `[Avg Rating]`

**Repeat vs one-time** — Donut: `[Repeat Users]` and `[One-Time Users]`. Since these are two separate measures, build it as a two-row table first (Enter Data: a `Segment` table with "Repeat"/"One-time") or just use two cards with a stacked bar — simpler and reads better on a projector.

**Rating by service** — Clustered bar.
- Y axis: `Bookings[ServiceType]`
- X axis: `[Avg Rating]`
- X-axis range: set minimum to 3.0, maximum 4.5. On a 0–5 axis every bar looks identical and the visual says nothing.

**Top customers** — Table: `Users[FirstName]`, `Users[LastName]`, `[Total Bookings]`, `[Net Revenue]`, `[Avg Rating]`. Top 10 by revenue.

---

## Page 4 — Payments and Promotions

**Payment mix over time** — 100% stacked column.
- X axis: `DateTable[Year Quarter]`
- Y axis: `[Net Revenue]`
- Legend: `Payments[PaymentType]`

**Payment method totals** — Clustered bar: `Payments[PaymentType]` by `[Net Revenue]`. EMI leads, which is worth a callout.

**Coupon impact** — Cards: `[Coupons Redeemed]`, `[Coupon Redemption Rate]`, `[Avg Discount %]`, `[Estimated Discount Value]`.

**Discounted vs undiscounted** — two cards side by side: `[Avg Value — Coupon Bookings]` and `[Avg Value — No Coupon]`. The comparison is the point; put them adjacent with a text box between them reading "Avg basket value".

**Ops follow-up table** — Table visual filtered to `Status` is `Pending` or `Cancelled`.
- Columns: `Bookings[BookingID]`, `Bookings[BookingDateTime]`, `Bookings[ServiceType]`, `Bookings[TotalPrice]`, `Bookings[Status]`
- Sort by `TotalPrice` descending
- Add a card above it: `[Value at Risk]`

---

## Step 5 — Finish

**Sync slicers.** View → Sync slicers pane. Sync the Year and ServiceType slicers across all four pages so filters persist as someone navigates.

**Navigation.** Insert → Buttons → Navigator → Page navigator. Drop it in the header band on page 1, then copy-paste to the other three pages so it sits in the same place.

**Tooltips.** Make a fifth page, set it to Tooltip page size, put `[Total Bookings]`, `[Net Revenue]`, `[Avg Rating]`, `[Failed Booking Rate]` on it, then set it as the tooltip for the service-level visuals. Cheap to build, and it's the thing that makes a report feel finished.

**Bookmarks.** One bookmark per year plus "All years", wired to buttons. Optional, but useful if you're presenting.

---

## Sanity check

Build the Executive Overview, then check these against your cards. If a number is off, the note in the last column says where to look.

| Measure | Expected | If it's wrong |
|---|---|---|
| Total Bookings | 900 | Duplicate rows on load |
| Net Revenue | ₹2,15,06,711 | You're using Gross — refunds not subtracted |
| Gross Revenue | ₹2,50,02,732 | — |
| Booking Value | ₹3,17,88,731 | This is baskets, not revenue |
| Active Users | 284 | — |
| Repeat Users | 242 | — |
| Avg Rating | 4.07 | — |
| Cancellation Rate | 9.2% | — |
| Failed Booking Rate | 19.2% | Missing Refunded in the measure |
| Coupons Redeemed | 217 | — |
| Coupon Redemption Rate | 24.1% | — |
| Avg Days To First Booking | 382 | Users with no bookings not filtered out |
| Hotel share of revenue | 64.2% | Relationship direction wrong on HotelBookings |

---

## Things that will go wrong

**Blank date relationship.** If `DateTable` won't join to `Bookings`, you skipped the `BookingDate` column — a Date/Time can't join to a Date.

**Every service shows identical revenue.** Cross-filter direction got set to Both somewhere. Set all relationships to Single.

**YoY shows -70% for 2026.** Working as designed — the year is half-loaded. Use `[Revenue YTD]` against `[Revenue YTD LY]`.

**Repeat Users returns the total user count.** `VALUES()` got replaced with `ALL()` in the measure, which strips the filter context.

**Donut percentages don't sum to 100.** A service is filtered out by a slicer somewhere on the page. Check Filters pane → this visual.
