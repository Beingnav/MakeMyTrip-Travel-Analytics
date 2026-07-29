# Power BI — MakeMyTrip Dashboard

A Power BI semantic model (17 tables, 16 relationships, a marked date table, 62 DAX measures) plus a four-page dashboard design.

## See it without Power BI

Open [`Live_Dashboard.html`](Live_Dashboard.html) in any browser. It's a fully interactive version of the dashboard with the real data embedded — slice by year, service and status, and click any bar or donut slice to cross-filter the whole report. No install, works offline.

`Dashboard_Mockup.html` is a static reference showing the intended four-page layout.

## Files

| File | What it is |
|---|---|
| `Live_Dashboard.html` | Interactive dashboard, real data, runs in a browser |
| `project/` | The Power BI project (`.pbip`) — open in Power BI Desktop |
| `BUILD_GUIDE.md` | Page-by-page instructions: every visual, and which field goes where |
| `DAX_measures.txt` | All 62 measures, copy-paste ready, grouped by folder |
| `FINDINGS.md` | The analysis write-up |

## Open the Power BI project

The semantic model is fully built; the report canvas has four named pages ready for visuals (Power BI's visual-layout format is fragile to hand-author, so the tedious model work is done and the drag-and-drop is left to you — `BUILD_GUIDE.md` walks every visual).

1. The CSVs are in `project/Data/`. Copy that folder to `C:\MakeMyTripData` (the default path the model expects).
2. Open `project/MakeMyTrip.pbip` in Power BI Desktop.
3. If your data ends up elsewhere: Home → Transform data → Manage parameters → **FolderPath** → set your path → Close & Apply.

If Desktop says `.pbip` isn't supported: Options → Preview features → enable **Power BI Project (.pbip) save option**, restart.

## Verify it loaded right

| Measure | Expected |
|---|---|
| Total Bookings | 900 |
| Net Revenue | ₹2,15,06,711 |
| Active Users | 284 |
| Avg Rating | 4.07 |
| Failed Booking Rate | 19.2% |

See the [main README](../README.md) for the net-vs-gross-vs-basket distinction and the note on synthetic data.
