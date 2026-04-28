WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM t.contract_date) AS year,
        p.state,
        n.neighbourhood_name,
        p.property_type,
        AVG(t.final_price) AS avg_sales_price,
        COUNT(t.transaction_id) AS number_of_sales
    FROM Transactions t
    JOIN Listings l ON t.listing_id = l.listing_id
    JOIN Properties p ON l.property_id = p.property_id
    JOIN Neighbourhoods n ON p.neighbourhood_id = n.neighbourhood_id
    WHERE t.transaction_type = 'Sale'
      AND t.transaction_status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM t.contract_date),
        p.state,
        n.neighbourhood_name,
        p.property_type
),
with_yoy AS (
    SELECT
        year,
        state,
        neighbourhood_name,
        property_type,
        avg_sales_price,
        LAG(avg_sales_price) OVER (
            PARTITION BY state, neighbourhood_name, property_type
            ORDER BY year
        ) AS previous_year_avg_price,
        ROUND(
            (
                (avg_sales_price - LAG(avg_sales_price) OVER (
                    PARTITION BY state, neighbourhood_name, property_type
                    ORDER BY year
                ))
                /
                NULLIF(LAG(avg_sales_price) OVER (
                    PARTITION BY state, neighbourhood_name, property_type
                    ORDER BY year
                ), 0)
            ) * 100,
            2
        ) AS yoy_growth_rate_pct,
        number_of_sales
    FROM yearly_sales
)
SELECT *
FROM with_yoy
WHERE yoy_growth_rate_pct IS NOT NULL
AND yoy_growth_rate_pct != 0
ORDER BY state, neighbourhood_name, property_type, year;