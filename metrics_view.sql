CREATE OR REPLACE VIEW annual_financial_metrics AS
WITH ranked_rows AS (
    SELECT
        company_id,
        fiscal_year_end,
        fiscal_year_label,
        reporting_scope,
        item_code,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY company_id, fiscal_year_end, reporting_scope, item_code
            ORDER BY imported_at DESC, raw_id DESC
        ) AS row_rank
    FROM financial_statement_raw
    WHERE item_code IS NOT NULL
), annual_values AS (
    SELECT
        company_id,
        fiscal_year_end,
        MAX(fiscal_year_label) AS fiscal_year_label,
        reporting_scope,
        MAX(amount) FILTER (WHERE item_code = 'revenue') AS revenue,
        MAX(amount) FILTER (WHERE item_code = 'net_income') AS net_income,
        MAX(amount) FILTER (WHERE item_code = 'current_assets') AS current_assets,
        MAX(amount) FILTER (WHERE item_code = 'current_liabilities') AS current_liabilities,
        MAX(amount) FILTER (WHERE item_code = 'total_equity') AS total_equity,
        MAX(amount) FILTER (WHERE item_code = 'short_term_borrowings') AS short_term_borrowings,
        MAX(amount) FILTER (WHERE item_code = 'long_term_borrowings') AS long_term_borrowings,
        MAX(amount) FILTER (WHERE item_code = 'current_maturities_of_debt') AS current_maturities_of_debt,
        MAX(amount) FILTER (WHERE item_code = 'total_debt') AS reported_total_debt
    FROM ranked_rows
    WHERE row_rank = 1
    GROUP BY company_id, fiscal_year_end, reporting_scope
), with_debt AS (
    SELECT
        annual_values.*,
        CASE
            WHEN reported_total_debt IS NOT NULL THEN reported_total_debt
            WHEN short_term_borrowings IS NULL
             AND long_term_borrowings IS NULL
             AND current_maturities_of_debt IS NULL THEN NULL
            ELSE COALESCE(short_term_borrowings, 0)
               + COALESCE(long_term_borrowings, 0)
               + COALESCE(current_maturities_of_debt, 0)
        END AS total_debt
    FROM annual_values
), with_prior_equity AS (
    SELECT
        with_debt.*,
        LAG(total_equity) OVER (
            PARTITION BY company_id, reporting_scope
            ORDER BY fiscal_year_end
        ) AS prior_year_equity,
        LAG(fiscal_year_end) OVER (
            PARTITION BY company_id, reporting_scope
            ORDER BY fiscal_year_end
        ) AS prior_fiscal_year_end
    FROM with_debt
)
SELECT
    c.nse_symbol,
    c.company_name,
    p.fiscal_year_end,
    p.fiscal_year_label,
    p.reporting_scope,
    p.revenue,
    p.net_income,
    p.current_assets,
    p.current_liabilities,
    p.total_equity,
    p.total_debt,
    CASE
        WHEN p.prior_fiscal_year_end = (p.fiscal_year_end - INTERVAL '1 year')::date
        THEN 100.0 * p.net_income
             / NULLIF((p.total_equity + p.prior_year_equity) / 2.0, 0)
    END AS roe_percent,
    p.current_assets / NULLIF(p.current_liabilities, 0) AS current_ratio,
    p.total_debt / NULLIF(p.total_equity, 0) AS debt_to_equity_ratio
FROM with_prior_equity AS p
JOIN companies AS c ON c.company_id = p.company_id;