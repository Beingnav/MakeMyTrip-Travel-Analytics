# Contributing

Thanks for your interest in this project. It's an analytics portfolio built on a synthetic MakeMyTrip-style dataset, explored three ways — an EDA notebook, a SQL database, and a Power BI model. Contributions that improve the analysis, fix errors, or extend any of the three are welcome.

Please read this before opening an issue or pull request.

## Ground rules

- **Keep the three projects in sync.** All three read from the same `data/` CSVs and should reach the same headline numbers (900 bookings, ₹2.15 Cr net revenue, hotels at 64.2% of revenue, 4.07 average rating). If a change alters a figure in one project, update the other two — and the READMEs — so they don't contradict each other.
- **The data is synthetic, and the caveats stay.** Every project deliberately separates real findings from generation artefacts (the 85% repeat rate, the ~382-day activation gap, the absence of seasonality). Don't quietly promote an artefact to a finding. If you add analysis that touches these, keep the caveat.
- **Net revenue is not the sum of payments.** Payments exist only for Confirmed, Completed and Refunded bookings, and refunds reverse. New revenue logic must respect this — use the `NetRevenue` column / measure, not a raw `SUM(PaymentAmount)`.
- **Be honest about what's verified.** If you add a query, measure, or chart, run it and confirm the output. Note anything you couldn't test (for example, a MySQL port you didn't execute).

## How to propose a change

1. **Open an issue first** for anything non-trivial — a new analysis, a schema change, a restructure. Small fixes (a typo, a broken link, a wrong number) can go straight to a pull request.
2. **Fork the repo, branch from `main`.** Use a short descriptive branch name like `fix-coupon-lift-query` or `add-cohort-retention`.
3. **Make the change, keep the diff focused.** One logical change per pull request.
4. **Open a pull request** describing what changed and why. If it affects a headline number, say which and show the before/after.

## Working in each area

### `eda/` — Jupyter notebook

- Environment: `pip install -r eda/requirements.txt`.
- Before committing, **Restart & Run All** so outputs are current, then re-export the HTML:
  ```bash
  jupyter nbconvert --to html --embed-images eda/MakeMyTrip_EDA.ipynb \
      --output MakeMyTrip_EDA_rendered
  ```
- Keep the existing chart style (the `seaborn` theme and colour constants defined in the setup cell) so figures stay consistent.
- Code cells should run top-to-bottom with no manual steps. Don't leave a cell that only works after running a later one.

### `sql/` — SQLite database and queries

- Rebuild the database after any schema or data change:
  ```bash
  cd sql && python load_data.py
  ```
  It runs a foreign-key integrity check and must report zero violations.
- New queries go in `03_analysis_queries.sql`, numbered, with a one-line comment saying what business question they answer and which technique they use (join, CTE, window function, etc.).
- Regenerate `query_results.txt` so the expected output matches:
  ```bash
  # re-run the results dump used to build query_results.txt
  ```
- If you change the schema, update `01_schema.sql`, `makemytrip_dump.sql`, and `ER_diagram.md` together, and regenerate the diagram image in `docs/images/`.
- Write portable SQL where you can. The README lists the MySQL/PostgreSQL differences; if you use a SQLite-specific function, add a porting note.

### `power-bi/` — semantic model and dashboard

- The model lives in `power-bi/project/` as a PBIP (text) project — commit the `.tmdl`/`.bim` and report definition changes, not a binary `.pbix`.
- New measures go in the `_Measures` table with a display folder and a format string, and should be documented in `DAX_measures.txt`.
- If you build report visuals, update `BUILD_GUIDE.md` and, if the interactive `Live_Dashboard.html` no longer matches, update it too.

## Style

- Prefer clarity over cleverness. These files double as reference material for people learning the tools.
- Markdown: sentence-case headings, prose over bullet soup where a sentence reads better.
- Don't commit generated cruft — `__pycache__`, `.ipynb_checkpoints`, editor folders. The `.gitignore` already covers the common ones.

## Data and licensing

- The dataset is synthetic and not affiliated with MakeMyTrip. Don't add real personal data, real credentials, or real transaction data.
- By contributing, you agree your contributions are licensed under the repository's [MIT License](LICENSE).

## Questions

Open an issue with the `question` label. For anything about a specific number, point to the file and line so it's easy to trace.
