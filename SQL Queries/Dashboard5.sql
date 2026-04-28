-- Dashboard 5 Rental Price Trend

WITH rental_trend AS (

    SELECT
        EXTRACT(YEAR FROM t.closing_date) AS year,

        p.state,
        n.neighbourhood_name,

        p.bedrooms,
        p.bathrooms,

        -- average rent price
        AVG(t.final_price) AS avg_rent_price,

        -- rental unit count
        COUNT(t.transaction_id) AS rental_unit_count

    FROM Transactions t

    LEFT JOIN Listings l
        ON t.listing_id = l.listing_id

    LEFT JOIN Properties p
        ON l.property_id = p.property_id

    LEFT JOIN Neighbourhoods n
        ON p.neighbourhood_id = n.neighbourhood_id

    WHERE
        t.transaction_type = 'Rent'
        AND t.transaction_status = 'Completed'

    GROUP BY
        EXTRACT(YEAR FROM t.closing_date),
        p.state,
        n.neighbourhood_name,
        p.bedrooms,
        p.bathrooms
),

rent_growth AS (

    SELECT
        year,
        state,
        neighbourhood_name,
        bedrooms,
        bathrooms,
        avg_rent_price,
        rental_unit_count,

        -- year over year rent price difference
        ROUND(
            (
                avg_rent_price -
                LAG(avg_rent_price) OVER (
                    PARTITION BY state, neighbourhood_name, bedrooms, bathrooms
                    ORDER BY year
                )
            )
            /
            NULLIF(
                LAG(avg_rent_price) OVER (
                    PARTITION BY state, neighbourhood_name, bedrooms, bathrooms
                    ORDER BY year
                ),
                0
            )
            * 100,
            2
        ) AS yoy_rent_price_difference

    FROM rental_trend
)

SELECT *
FROM rent_growth
WHERE yoy_rent_price_difference IS NOT NULL
ORDER BY state, neighbourhood_name, year;

-- Dashboard 5 analyzes rental price trends across states and neighbourhoods over time. 
-- The query calculates average rent price, rental unit count, and year-over-year rent price difference.

-- The YoY rent price difference shows how rental prices changed compared with the previous year for the same state, neighbourhood, bedrooms, and bathrooms. 
-- A positive YoY value means rent increased, while a negative value means rent decreased. 
-- Null values appear when there is no previous year available for comparison.