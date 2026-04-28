WITH home_sales AS (
    SELECT
        EXTRACT(YEAR FROM t.contract_date) AS year,
        p.state,
        n.neighbourhood_name,
        p.bedrooms,
        p.bathrooms,
        p.property_id,
        t.final_price,
        COUNT(oh.open_house_id) AS open_house_count,
        CASE
            WHEN COUNT(oh.open_house_id) > 0 THEN 'Yes'
            ELSE 'No'
        END AS has_open_house
    FROM Transactions t
    JOIN Listings l
        ON t.listing_id = l.listing_id
    JOIN Properties p
        ON l.property_id = p.property_id
    JOIN Neighbourhoods n
        ON p.neighbourhood_id = n.neighbourhood_id
    LEFT JOIN OpenHouses oh
        ON p.property_id = oh.property_id
    WHERE t.transaction_type = 'Sale'
      AND t.transaction_status = 'Completed'
    GROUP BY
        EXTRACT(YEAR FROM t.contract_date),
        p.state,
        n.neighbourhood_name,
        p.bedrooms,
        p.bathrooms,
        p.property_id,
        t.final_price
),
grouped_sales AS (
    SELECT
        year,
        state,
        neighbourhood_name,
        bedrooms,
        bathrooms,
        has_open_house,
        AVG(final_price) AS avg_final_sold_price,
        COUNT(property_id) AS number_of_sold_homes,
        AVG(open_house_count) AS avg_open_house_count
    FROM home_sales
    GROUP BY
        year,
        state,
        neighbourhood_name,
        bedrooms,
        bathrooms,
        has_open_house
)
SELECT *
FROM grouped_sales
ORDER BY year, state, neighbourhood_name, bedrooms, bathrooms, has_open_house;