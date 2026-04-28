-- Dashboard 2: Agent Performance 
-- Measures productivity, efficiency, revenue contribution

SELECT
    a.agent_id,
    a.first_name || ' ' || a.last_name AS agent_name,
    o.office_name,
    EXTRACT(YEAR FROM l.start_date)    AS year,
    t.transaction_type,

    COUNT(DISTINCT l.listing_id)       AS listing_count,
    COUNT(DISTINCT t.transaction_id)   AS transaction_count,

    ROUND(
        COUNT(DISTINCT t.transaction_id)::DECIMAL /
        NULLIF(COUNT(DISTINCT l.listing_id), 0),
        2
    ) AS conversion_ratio,

    COALESCE(appt.completed_appointments, 0)  AS completed_appointments,
    COALESCE(appt.unique_clients_reached, 0)  AS unique_clients_reached,

    COALESCE(SUM(CASE
        WHEN t.transaction_type = 'Rent'
        THEN c.commission_amount ELSE 0
    END), 0) AS rental_deals_income,

    COALESCE(SUM(CASE
        WHEN t.transaction_type = 'Sale'
        THEN c.commission_amount ELSE 0
    END), 0) AS sales_closed_income,

    COALESCE(SUM(c.commission_amount), 0) AS total_income

FROM Agents a

JOIN Offices o
    ON a.office_id = o.office_id

LEFT JOIN Listings l
    ON a.agent_id = l.agent_id

LEFT JOIN Transactions t
    ON l.listing_id = t.listing_id


LEFT JOIN (
    SELECT
        agent_id,
        transaction_id,
        SUM(commission_amount) AS commission_amount
    FROM Commissions
    GROUP BY agent_id, transaction_id
) c
    ON  a.agent_id       = c.agent_id
    AND t.transaction_id = c.transaction_id


LEFT JOIN (
    SELECT
        ai.agent_id,
        COUNT(DISTINCT CASE
            WHEN ap.status = 'Completed' THEN ap.appointment_id
        END)                          AS completed_appointments,
        COUNT(DISTINCT ai.client_id)  AS unique_clients_reached
    FROM AppointmentInteractions ai
    LEFT JOIN Appointments ap
        ON ai.appointment_id = ap.appointment_id
    GROUP BY ai.agent_id
) appt
    ON a.agent_id = appt.agent_id

GROUP BY
    a.agent_id,
    a.first_name,
    a.last_name,
    o.office_name,
    EXTRACT(YEAR FROM l.start_date),
    t.transaction_type,
    appt.completed_appointments,
    appt.unique_clients_reached

ORDER BY
    total_income DESC;
