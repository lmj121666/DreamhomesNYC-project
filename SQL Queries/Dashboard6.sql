-- ============================================================
-- Dashboard 6: Ownership Trends & Investor Activity
-- Purpose:
-- Analyze long-term ownership behavior and multi-property owner activity.
--
-- Filters:
-- Year
-- State
-- Property Type
-- Pandemic Period
--
-- Tables Used:
-- PropertyOwners
-- Properties
-- Clients
-- ============================================================


-- ============================================================
-- Optional: Drop old dashboard views if they already exist
-- ============================================================

DROP VIEW IF EXISTS dash6_owner_detail;
DROP VIEW IF EXISTS dash6_holding_time_by_property_type;
DROP VIEW IF EXISTS dash6_yearly_ownership_trend;
DROP VIEW IF EXISTS dash6_kpi_summary;
DROP VIEW IF EXISTS dash6_active_ownership_base;


-- ============================================================
-- 1. Base View
-- Expands each ownership record into active ownership years.
-- Example:
-- If someone owned a property from 2018 to 2022,
-- this creates rows for 2018, 2019, 2020, 2021, 2022.
-- ============================================================

CREATE OR REPLACE VIEW dash6_active_ownership_base AS
SELECT
    po.property_owner_id,
    po.client_id,
    c.first_name,
    c.last_name,
    c.email,

    po.property_id,
    p.property_type,
    p.state,
    p.city,

    po.ownership_start_date,
    po.ownership_end_date,
    po.is_current_owner,

    active_year.year AS year,

    CASE
        WHEN active_year.year <= 2019
            THEN 'Pre-Pandemic'
        ELSE 'Post-Pandemic'
    END AS pandemic_period,

    ROUND(
        (
            COALESCE(po.ownership_end_date, CURRENT_DATE)
            - po.ownership_start_date
        ) / 365.0,
        2
    ) AS holding_time_years

FROM PropertyOwners po
JOIN Properties p
    ON po.property_id = p.property_id
JOIN Clients c
    ON po.client_id = c.client_id
JOIN LATERAL generate_series(
    EXTRACT(YEAR FROM po.ownership_start_date)::int,
    EXTRACT(YEAR FROM COALESCE(po.ownership_end_date, CURRENT_DATE))::int
) AS active_year(year)
    ON TRUE;


-- ============================================================
-- 2. KPI Summary View
-- Use this for dashboard KPI cards.
-- This gives overall ownership metrics.
-- ============================================================

CREATE OR REPLACE VIEW dash6_kpi_summary AS
WITH owner_property_counts AS (
    SELECT
        client_id,
        COUNT(DISTINCT property_id) AS property_count,
        ROUND(AVG(holding_time_years), 2) AS avg_holding_time_years
    FROM dash6_active_ownership_base
    WHERE is_current_owner = TRUE
    GROUP BY client_id
)

SELECT
    ROUND(AVG(avg_holding_time_years), 2) AS avg_holding_time_years,

    COUNT(DISTINCT client_id) AS total_owner_count,

    COUNT(DISTINCT CASE
        WHEN property_count > 1 THEN client_id
    END) AS multi_property_owner_count,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN property_count > 1 THEN client_id
        END) * 100.0
        / NULLIF(COUNT(DISTINCT client_id), 0),
        2
    ) AS multi_property_owner_percentage

FROM owner_property_counts;


-- ============================================================
-- 3. Yearly Ownership Trend View
-- Use this for the line chart.
--
-- Recommended chart:
-- X-axis: year
-- Y-axis: multi_property_owner_count
-- Color: state or property_type
-- Filters: year, state, property_type, pandemic_period
-- ============================================================

CREATE OR REPLACE VIEW dash6_yearly_ownership_trend AS
WITH owner_property_count_by_year AS (
    SELECT
        year,
        state,
        property_type,
        pandemic_period,
        client_id,
        COUNT(DISTINCT property_id) AS property_count
    FROM dash6_active_ownership_base
    GROUP BY
        year,
        state,
        property_type,
        pandemic_period,
        client_id
),

yearly_summary AS (
    SELECT
        year,
        state,
        property_type,
        pandemic_period,

        COUNT(DISTINCT client_id) AS total_owner_count,

        COUNT(DISTINCT CASE
            WHEN property_count > 1 THEN client_id
        END) AS multi_property_owner_count,

        ROUND(
            COUNT(DISTINCT CASE
                WHEN property_count > 1 THEN client_id
            END) * 100.0
            / NULLIF(COUNT(DISTINCT client_id), 0),
            2
        ) AS multi_property_owner_percentage

    FROM owner_property_count_by_year
    GROUP BY
        year,
        state,
        property_type,
        pandemic_period
),

yoy_summary AS (
    SELECT
        year,
        state,
        property_type,
        pandemic_period,
        total_owner_count,
        multi_property_owner_count,
        multi_property_owner_percentage,

        LAG(multi_property_owner_count) OVER (
            PARTITION BY state, property_type
            ORDER BY year
        ) AS previous_year_multi_property_owner_count

    FROM yearly_summary
)

SELECT
    year,
    state,
    property_type,
    pandemic_period,
    total_owner_count,
    multi_property_owner_count,
    multi_property_owner_percentage,
    previous_year_multi_property_owner_count,

    CASE
        WHEN previous_year_multi_property_owner_count IS NULL
             OR previous_year_multi_property_owner_count = 0
            THEN NULL
        ELSE ROUND(
            (
                multi_property_owner_count
                - previous_year_multi_property_owner_count
            ) * 100.0
            / previous_year_multi_property_owner_count,
            2
        )
    END AS yoy_percent_change_multi_property_owners

FROM yoy_summary;


-- ============================================================
-- 4. Holding Time by Property Type View
-- Use this for the bar chart.
--
-- Recommended chart:
-- X-axis: property_type
-- Y-axis: avg_holding_time_years
-- Color: pandemic_period
-- Filters: state, property_type, pandemic_period
-- ============================================================

CREATE OR REPLACE VIEW dash6_holding_time_by_property_type AS
SELECT
    state,
    property_type,
    pandemic_period,

    ROUND(AVG(holding_time_years), 2) AS avg_holding_time_years,

    COUNT(DISTINCT client_id) AS owner_count,
    COUNT(DISTINCT property_id) AS property_count

FROM dash6_active_ownership_base

GROUP BY
    state,
    property_type,
    pandemic_period;


-- ============================================================
-- 5. Owner Detail View
-- Use this for the detail table.
--
-- Recommended table fields:
-- Owner Name
-- Email
-- State
-- Property Type
-- Property Count
-- Average Holding Time
-- Current Owner Flag
-- ============================================================

CREATE OR REPLACE VIEW dash6_owner_detail AS
SELECT
    client_id,
    first_name,
    last_name,
    email,
    state,
    property_type,

    COUNT(DISTINCT property_id) AS property_count,

    ROUND(AVG(holding_time_years), 2) AS avg_holding_time_years,

    MAX(CASE
        WHEN is_current_owner = TRUE THEN 1
        ELSE 0
    END) AS has_current_ownership,

    CASE
        WHEN COUNT(DISTINCT property_id) > 1
            THEN 'Multi-Property Owner'
        ELSE 'Single-Property Owner'
    END AS owner_type

FROM dash6_active_ownership_base

GROUP BY
    client_id,
    first_name,
    last_name,
    email,
    state,
    property_type;


-- ============================================================
-- 6. Quick Checks
-- Run these after creating the views.
-- ============================================================

SELECT *
FROM dash6_kpi_summary;

SELECT *
FROM dash6_yearly_ownership_trend
ORDER BY year, state, property_type;

SELECT *
FROM dash6_holding_time_by_property_type
ORDER BY state, property_type;

SELECT *
FROM dash6_owner_detail
ORDER BY property_count DESC, avg_holding_time_years DESC;