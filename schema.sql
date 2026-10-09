CREATE TABLE IF NOT EXISTS companies (
    company_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nse_symbol varchar(20) NOT NULL UNIQUE,
    company_name varchar(200) NOT NULL,
    sector varchar(100)
);

CREATE TABLE IF NOT EXISTS financial_line_items (
    item_code varchar(40) PRIMARY KEY,
    item_name varchar(100) NOT NULL,
    statement_type varchar(20) NOT NULL
        CHECK (statement_type IN ('income', 'balance_sheet')),
    UNIQUE (item_code, statement_type)
);

INSERT INTO financial_line_items (item_code, item_name, statement_type) VALUES
    ('revenue', 'Revenue', 'income'),
    ('net_income', 'Net income / profit after tax', 'income'),
    ('current_assets', 'Current assets', 'balance_sheet'),
    ('current_liabilities', 'Current liabilities', 'balance_sheet'),
    ('total_equity', 'Total shareholders equity', 'balance_sheet'),
    ('short_term_borrowings', 'Short-term borrowings', 'balance_sheet'),
    ('long_term_borrowings', 'Long-term borrowings', 'balance_sheet'),
    ('current_maturities_of_debt', 'Current maturities of long-term debt', 'balance_sheet'),
    ('total_debt', 'Total interest-bearing debt', 'balance_sheet')
ON CONFLICT (item_code) DO NOTHING;

CREATE TABLE IF NOT EXISTS financial_statement_raw (
    raw_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_id integer NOT NULL REFERENCES companies(company_id),
    fiscal_year_end date NOT NULL,
    fiscal_year_label varchar(9) NOT NULL,
    statement_type varchar(20) NOT NULL
        CHECK (statement_type IN ('income', 'balance_sheet')),
    reporting_scope varchar(20) NOT NULL
        CHECK (reporting_scope IN ('standalone', 'consolidated')),
    item_code varchar(40),
    reported_line_item varchar(200) NOT NULL,
    amount numeric(20, 4),
    unit varchar(30) NOT NULL DEFAULT 'INR crore',
    currency_code char(3) NOT NULL DEFAULT 'INR',
    source_name varchar(150) NOT NULL,
    source_url text,
    source_file varchar(255),
    source_row_number integer,
    imported_at timestamptz NOT NULL DEFAULT now(),
    FOREIGN KEY (item_code, statement_type)
        REFERENCES financial_line_items(item_code, statement_type)
);

CREATE INDEX IF NOT EXISTS idx_financial_raw_company_year
    ON financial_statement_raw (company_id, fiscal_year_end);

CREATE INDEX IF NOT EXISTS idx_financial_raw_item_year
    ON financial_statement_raw (item_code, fiscal_year_end);

CREATE UNIQUE INDEX IF NOT EXISTS uq_financial_raw_company_year_scope_item
    ON financial_statement_raw (company_id, fiscal_year_end, reporting_scope, item_code)
    WHERE item_code IS NOT NULL;