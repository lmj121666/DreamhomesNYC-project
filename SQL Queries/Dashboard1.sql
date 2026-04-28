-- Dashboard 1
-- Calculate office net revenue by year
-- net revenue = salary + commission - fees - open house cost - office rent
WITH office_years AS (
    SELECT 
        o.office_id,
        o.office_name,
        o.state,
        o.office_rent,
        EXTRACT(YEAR FROM t.contract_date) AS year
    FROM Offices o
    JOIN Agents a
        ON o.office_id = a.office_id
    JOIN Commissions c
        ON a.agent_id = c.agent_id
    JOIN Transactions t
        ON c.transaction_id = t.transaction_id
    GROUP BY o.office_id, o.office_name, o.state, o.office_rent, EXTRACT(YEAR FROM t.contract_date)
),

salary_by_year AS (
    SELECT
        oy.office_id,
        oy.year,
        SUM(a.base_salary) AS total_base_salary
    FROM office_years oy
    JOIN Agents a
        ON oy.office_id = a.office_id
    WHERE EXTRACT(YEAR FROM a.hire_date) <= oy.year
    GROUP BY oy.office_id, oy.year
),

commission_by_year AS (
    SELECT
        a.office_id,
        EXTRACT(YEAR FROM t.contract_date) AS year,
        SUM(c.commission_amount) AS total_commission
    FROM Commissions c
    JOIN Transactions t
        ON c.transaction_id = t.transaction_id
    JOIN Agents a
        ON c.agent_id = a.agent_id
    GROUP BY a.office_id, EXTRACT(YEAR FROM t.contract_date)
),

fees_by_year AS (
    SELECT
        a.office_id,
        EXTRACT(YEAR FROM t.contract_date) AS year,
        SUM(COALESCE(e.legal_fees, 0) + COALESCE(e.other_expenses, 0)) AS total_fees
    FROM Expenses e
    JOIN Transactions t
        ON e.transaction_id = t.transaction_id
    JOIN Listings l
        ON t.listing_id = l.listing_id
    JOIN Agents a
        ON l.agent_id = a.agent_id
    GROUP BY a.office_id, EXTRACT(YEAR FROM t.contract_date)
),

openhouse_by_year AS (
    SELECT
        a.office_id,
        EXTRACT(YEAR FROM oh.start_time) AS year,
        SUM(oh.cost) AS total_openhouse_cost
    FROM OpenHouses oh
    JOIN Agents a
        ON oh.hosting_agent_id = a.agent_id
    GROUP BY a.office_id, EXTRACT(YEAR FROM oh.start_time)
)

SELECT
    oy.year,
    oy.office_id,
    oy.office_name,
    oy.state,
    COALESCE(s.total_base_salary, 0) AS total_base_salary,
    COALESCE(c.total_commission, 0) AS total_commission,
    COALESCE(f.total_fees, 0) AS total_fees,
    COALESCE(o.total_openhouse_cost, 0) AS total_openhouse_cost,
    oy.office_rent,
    COALESCE(s.total_base_salary, 0)
    + COALESCE(c.total_commission, 0)
    - COALESCE(f.total_fees, 0)
    - COALESCE(o.total_openhouse_cost, 0)
    - oy.office_rent AS net_revenue
FROM office_years oy
LEFT JOIN salary_by_year s
    ON oy.office_id = s.office_id AND oy.year = s.year
LEFT JOIN commission_by_year c
    ON oy.office_id = c.office_id AND oy.year = c.year
LEFT JOIN fees_by_year f
    ON oy.office_id = f.office_id AND oy.year = f.year
LEFT JOIN openhouse_by_year o
    ON oy.office_id = o.office_id AND oy.year = o.year
ORDER BY oy.year, oy.office_id;

--This query calculates the yearly net revenue for each office. 
--First, I aggregate base salary, commission, transaction-related fees, and open house costs at the office-year level. 
--Then I combine these components and subtract office rent once per office-year to avoid double counting. 
--The result can be used to compare revenue across offices and across states over time.
