CREATE TEMP TABLE financial_csv_import (
    nse_symbol varchar(20) NOT NULL,
    company_name varchar(200) NOT NULL,
    fiscal_year_end date NOT NULL,
    fiscal_year_label varchar(9) NOT NULL,
    statement_type varchar(20) NOT NULL,
    reporting_scope varchar(20) NOT NULL,
    item_code varchar(40),
    reported_line_item varchar(200) NOT NULL,
    amount numeric(20, 4),
    unit varchar(30) NOT NULL,
    currency_code char(3) NOT NULL,
    source_name varchar(150) NOT NULL,
    source_url text
);

\copy financial_csv_import FROM 'financial_data.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO companies (nse_symbol, company_name)
SELECT DISTINCT nse_symbol, company_name
FROM financial_csv_import
ON CONFLICT (nse_symbol) DO NOTHING;

INSERT INTO financial_statement_raw (
    company_id,
    fiscal_year_end,
    fiscal_year_label,
    statement_type,
    reporting_scope,
    item_code,
    reported_line_item,
    amount,
    unit,
    currency_code,
    source_name,
    source_url,
    source_file
)
SELECT
    c.company_id,
    i.fiscal_year_end,
    i.fiscal_year_label,
    i.statement_type,
    i.reporting_scope,
    i.item_code,
    i.reported_line_item,
    i.amount,
    i.unit,
    i.currency_code,
    i.source_name,
    i.source_url,
    'financial_data.csv'
FROM financial_csv_import AS i
JOIN companies AS c ON c.nse_symbol = i.nse_symbol
ON CONFLICT (company_id, fiscal_year_end, reporting_scope, item_code)
    WHERE item_code IS NOT NULL
DO UPDATE SET
    fiscal_year_label = EXCLUDED.fiscal_year_label,
    statement_type = EXCLUDED.statement_type,
    reported_line_item = EXCLUDED.reported_line_item,
    amount = EXCLUDED.amount,
    unit = EXCLUDED.unit,
    currency_code = EXCLUDED.currency_code,
    source_name = EXCLUDED.source_name,
    source_url = EXCLUDED.source_url,
    source_file = EXCLUDED.source_file,
    imported_at = now();