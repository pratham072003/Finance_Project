# NSE Finance Dashboard Data

PostgreSQL data preparation for a Power BI financial dashboard covering seven NSE-listed companies. The annual data is in INR crore and uses consolidated reporting where available.

## Setup

Create a PostgreSQL database named `finance_dashboard`, then run these scripts from this directory:

```sh
psql -d finance_dashboard -f schema.sql
psql -d finance_dashboard -f metrics_view.sql
psql -d finance_dashboard -f seed_companies.sql
psql -d finance_dashboard -f import_financial_data.sql
```

The import script reads `financial_data.csv` and upserts the rows. The `annual_financial_metrics` view is the intended Power BI data source. Source URLs and units are stored with each imported figure.

The `*.xlsx` files are the original Screener exports. Financial statement values used for the CSV were checked against linked annual reports where available.