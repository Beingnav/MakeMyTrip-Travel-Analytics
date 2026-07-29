# MakeMyTrip — Power BI project

This is a real Power BI project. The **semantic model is fully built**: 17 tables, 16 relationships, a marked date table, and 62 measures. The report canvas is empty — four named pages waiting for visuals.

That split is deliberate. The model is the part that's tedious and error-prone to set up by hand, so it's done. Dropping visuals onto a canvas is the part that's quick, and it's what you'd want to control anyway.

---

## Open it

**1. Put the data somewhere permanent.**

The `Data` folder here holds all 16 CSVs. Copy it to a fixed path — `C:\MakeMyTripData` is the default the model expects, and using it means you can skip step 3.

**2. Open `MakeMyTrip.pbip` in Power BI Desktop.**

Double-click it. Desktop opens the project and starts loading.

If Desktop says the `.pbip` format isn't supported, you're on an older build: File → Options and settings → Options → Preview features → tick **Power BI Project (.pbip) save option**, restart, then try again.

**3. Only if your CSVs aren't at `C:\MakeMyTripData`:**

The first refresh will fail with a "file not found" error. That's expected and harmless.

Home → Transform data → Manage parameters → **FolderPath** → change it to wherever you put the `Data` folder (no trailing backslash) → Close & Apply.

---

## What you get

**Tables** — the 15 source tables plus `DateTable` (a real calendar, marked as a date table so time intelligence works) and `_Measures`.

**Already handled in Power Query**, so there are no calculated columns to write:

| Column | Table | What it's for |
|---|---|---|
| `BookingDate` | Bookings | Date-only, so it joins to the calendar |
| `Status Order` | Bookings | Makes Status sort Completed → Cancelled instead of alphabetically |
| `Price Band` | Bookings | Buckets for the value-distribution chart |
| `Registration Cohort` | Users | Month label for cohort analysis |
| `Nights` | Hotels | Checkout minus checkin |

`Users[Password]` is dropped on load. `Email` and `PhoneNumber` are hidden.

**Relationships** — all 16, single-direction, with `Reviews → Users` correctly set inactive (it already reaches Users through Bookings; two active paths would be ambiguous).

**Measures** — 62, in eight display folders: Volume, Revenue, Status, Customers, Reviews, Coupons, Time, Mix. Currency and percentage formatting is set on each one, so visuals come out formatted without extra work.

---

## Build the pages

`Build_Guide.md` lists every visual for all four pages — visual type, and which field goes in which well. The pages are already created and named, so work straight down the guide.

Start with the Executive Overview, then check your cards:

| Measure | Should read |
|---|---|
| Total Bookings | 900 |
| Net Revenue | ₹2,15,06,711 |
| Gross Revenue | ₹2,50,02,732 |
| Active Users | 284 |
| Avg Rating | 4.07 |
| Failed Booking Rate | 19.2% |

If those match, the model loaded correctly.

---

## One thing to know before you present

Payments exist only for Confirmed, Completed and Refunded bookings — Pending and Cancelled never paid. So `Gross Revenue` (₹2.50 Cr) is smaller than `Booking Value` (₹3.18 Cr), and `Net Revenue` (₹2.15 Cr) is smaller again after refunds. All three are correct; they answer different questions. Headline Net Revenue.

Also: the data stops on 20 July 2026, so any full-year comparison will show 2026 collapsing. Use `Revenue YTD` against `Revenue YTD LY` instead.
