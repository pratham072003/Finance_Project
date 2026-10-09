INSERT INTO companies (nse_symbol, company_name, sector) VALUES
    ('RELIANCE', 'Reliance Industries Ltd', 'Energy'),
    ('TCS', 'Tata Consultancy Services Ltd', 'Information Technology'),
    ('INFY', 'Infosys Ltd', 'Information Technology'),
    ('HINDUNILVR', 'Hindustan Unilever Ltd', 'Consumer Goods'),
    ('ITC', 'ITC Ltd', 'Consumer Goods'),
    ('BHARTIARTL', 'Bharti Airtel Ltd', 'Telecommunications'),
    ('TITAN', 'Titan Company Ltd', 'Consumer Discretionary')
ON CONFLICT (nse_symbol) DO NOTHING;