# MakeMyTrip — Exploratory Data Analysis

An EDA of a synthetic travel-booking dataset (flights, hotels, buses, trains, car rentals; India; Jan 2024 – Jul 2026).

## What's here

| File | What it is |
|---|---|
| `MakeMyTrip_EDA.ipynb` | The notebook — run it yourself, all outputs already saved |
| `MakeMyTrip_EDA_rendered.html` | The notebook with every chart and table baked in — **open this to read without running anything** |
| `data/` | The 15 source CSVs the notebook loads |
| `requirements.txt` | The libraries needed to run it |

## Read it now

Open `MakeMyTrip_EDA_rendered.html` in any browser. It's the fully executed notebook — 11 charts, all tables, all commentary — and needs nothing installed.

## Run it yourself

```bash
pip install -r requirements.txt
jupyter notebook MakeMyTrip_EDA.ipynb
```

Then Kernel → Restart & Run All. Keep the `data/` folder next to the notebook.

## How the notebook is organised

1. **Setup and load** — all 15 tables, dates parsed
2. **Structure** — the three table roles and how they connect
3. **Data quality** — missing values, duplicates, referential integrity, and a check that the `ServiceType` shortcut agrees with the bridge tables
4. **Analysis table** — flattening everything onto one row per booking
5. **Univariate** — distributions of value, service, status, payment, rating
6. **Bivariate** — value by service, volume-vs-revenue divergence, failure rates, a correlation matrix, the coupon comparison
7. **Time** — growth, and a seasonality check
8. **Outliers and two artefacts** — high-value bookings, and why the retention numbers can't be taken at face value
9. **Findings and caveats**

## The one thing worth knowing before you present it

The data is synthetic, and three things that look like insights are actually properties of the generator: the 85% repeat rate, the ~382-day activation gap, and the total absence of seasonality. The notebook separates these from the real findings deliberately — flagging them is what shows the analysis was read critically rather than run on autopilot. Section 9 lists both sides.

The genuine findings hold up: hotels drive 64% of revenue from 29% of bookings, one booking in five never converts, and the low-value ground-transport services are also the least reliable.
