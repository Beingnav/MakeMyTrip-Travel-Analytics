# What the data actually shows

Material for the analysis section of your report. Every figure here is computed from the dataset, so it will match your dashboard once the model is built. The caveats matter as much as the findings — flagging the limits of synthetic data is usually what separates a good project write-up from a generic one.

---

## 1. Hotels carry the business; flights carry the traffic

| Service | Bookings | Share of bookings | Net revenue | Share of revenue | Revenue per booking |
|---|---|---|---|---|---|
| Hotel | 258 | 28.7% | ₹1.38 Cr | 64.2% | ₹53,506 |
| Flight | 344 | 38.2% | ₹65.0 L | 30.2% | ₹18,906 |
| Train | 95 | 10.6% | ₹4.9 L | 2.3% | ₹5,199 |
| Bus | 139 | 15.4% | ₹4.5 L | 2.1% | ₹3,220 |
| Car rental | 64 | 7.1% | ₹2.6 L | 1.2% | ₹4,022 |

Flights are the most-booked service but generate less than half the revenue of hotels. One hotel booking is worth 2.8 flight bookings and 16.6 bus bookings.

The strategic reading: flights are an acquisition channel, hotels are where the money is. A platform in this shape should be measuring flight bookings on their attach rate to hotel bookings, not on their own revenue. That's the kind of conclusion worth putting on the executive page as a text box.

**Ground transport is 33% of booking volume and 5.6% of revenue.** It also has the worst reliability (below). That combination — high operational load, low return, high failure — is the sharpest finding in the dataset.

---

## 2. One rupee in five never converts

Of 900 bookings:

- 625 reached Confirmed or Completed
- 102 sit Pending
- 83 were Cancelled
- 90 were Refunded

Cancellation rate 9.2%, refund rate 10.0%, combined failure rate **19.2%**.

Money side:

| | Amount |
|---|---|
| Total basket value (Bookings.TotalPrice) | ₹3.18 Cr |
| Gross payments received | ₹2.50 Cr |
| Refunded back out | ₹35.0 L |
| **Net revenue** | **₹2.15 Cr** |
| Realisation rate | 67.7% |
| Unconverted basket value (pending + cancelled) | ₹67.9 L |

Failure rate varies sharply by service:

| Service | Cancelled | Refunded | Combined |
|---|---|---|---|
| Train | 10.5% | 16.8% | 27.3% |
| Car rental | 12.5% | 14.1% | 26.6% |
| Bus | 10.8% | 13.7% | 24.5% |
| Flight | 7.8% | 9.0% | 16.8% |
| Hotel | 8.9% | 5.8% | 14.7% |

Hotels are the most reliable *and* the most valuable. Trains fail nearly twice as often as hotels.

---

## 3. Satisfaction is solid but not uniform

339 reviews across 900 bookings — 37.7% coverage. Average rating 4.07.

- 5 star: 147 · 4 star: 109 · 3 star: 52 · 2 star: 21 · 1 star: 10
- Promoters (4–5) 75.5%, detractors (1–2) 9.1%, satisfaction score **+66**

By service: Flight 4.19 · Hotel 4.03 · Bus 4.00 · Train 4.00 · Car rental 3.74.

Car rental is the outlier on both axes — lowest rating and second-worst failure rate, on the smallest revenue base. If the report needs a recommendation, "fix or exit car rentals" is the one the data supports.

---

## 4. Payments skew toward credit

| Method | Net revenue | Share |
|---|---|---|
| EMI | ₹46.2 L | 21.5% |
| Debit Card | ₹39.5 L | 18.4% |
| UPI | ₹35.3 L | 16.4% |
| Credit Card | ₹35.1 L | 16.3% |
| Net Banking | ₹31.6 L | 14.7% |
| Wallet | ₹27.3 L | 12.7% |

EMI leading by revenue while UPI leads by transaction count (134 payments) is the interesting split: UPI handles frequency, EMI handles size. Consistent with hotels dominating high-value baskets.

---

## 5. The coupon programme does not pay for itself

- 217 bookings redeemed a coupon — 24.1% redemption rate
- Average discount 16.7%
- Estimated value given away: ₹13.3 L
- Average basket **with** coupon: ₹36,974
- Average basket **without**: ₹34,796

A 6.3% basket lift against a 16.7% discount. On these numbers the programme costs roughly ₹2.6 for every ₹1 of incremental basket value it generates.

Be careful how you phrase this: the data can't tell you whether those bookings would have happened without the coupon, which is the question that actually decides it. The honest statement is that there's no evidence in this dataset of a lift large enough to justify the discount rate, and that establishing causality would need an A/B holdout.

---

## 6. Demand is flat, not growing

| Year | Bookings | Basket value |
|---|---|---|
| 2024 | 357 | ₹1.21 Cr |
| 2025 | 355 | ₹1.23 Cr |
| 2026 (to 20 Jul) | 188 | ₹75 L |

2024 and 2025 are essentially identical. 2026 is tracking to a similar annualised figure. There's no growth trend to find here, and no meaningful seasonality either — quarterly bookings sit between 74 and 101 across the whole period.

Don't manufacture a trend narrative out of quarterly noise. The correct finding is that the series is flat, which is itself worth stating.

---

## Limitations to state explicitly

This section will do more for your marks than another chart.

**The data is synthetic.** It was generated to match a schema, not sampled from real transactions. It's realistic in shape — Indian cities, real airline names, plausible price ranges — but no real customer behaviour is encoded in it.

**Three findings are generation artefacts, not insights:**

1. *85% repeat rate.* 900 bookings were distributed across 284 users roughly uniformly, so almost everyone books more than once. A real OTA sees repeat rates well below this.
2. *382 days to first booking.* Registration dates run from 2021 while bookings start in 2024, so the gap is a function of the date ranges chosen, not of onboarding friction.
3. *No seasonality.* Booking dates were drawn uniformly. Real travel demand has strong Diwali, summer and wedding-season peaks. Their absence is a property of the generator.

**Two structural gaps in the schema:**

- There's no search, view or cart data, so nothing upstream of a booking can be analysed. Conversion funnel work is impossible.
- `Bookings.ServiceType` is a convenience column added for Power BI. In the original schema, service type is only implied by which bridge table holds the BookingID. If you're presenting the model, say this — it's the kind of detail that shows you read the schema rather than just loaded it.

**One thing to do if you want to strengthen the project:** swap in real data from the SQL schema, or regenerate the synthetic set with realistic distributions — a power-law spread of bookings per user and a seasonal booking curve. The model, relationships and every measure in the DAX file will keep working unchanged as long as the column names match.
