-- ============================================
-- PROJECT 3 : CUSTOMER GROWTH & RETENTION
-- ============================================


-- ============================================
-- CUSTOMER SUMMARY VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT
    customer_id,
    customer_name,

    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_date) AS active_order_days,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    ROUND(
        SUM(profit)::numeric / NULLIF(SUM(sales)::numeric, 0) * 100,
        2
    ) AS profit_margin_pct,

    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_sales DESC;


-- ============================================
-- TEST CUSTOMER SUMMARY VIEW
-- ============================================

SELECT *
FROM vw_customer_summary
LIMIT 20;


-- ============================================
-- MONTHLY CUSTOMER REVENUE VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_monthly_customer_revenue AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,

    customer_id,
    customer_name,

    ROUND(SUM(sales)::numeric, 2) AS monthly_sales,
    ROUND(SUM(profit)::numeric, 2) AS monthly_profit,

    COUNT(DISTINCT order_id) AS monthly_orders

FROM orders_clean

GROUP BY
    DATE_TRUNC('month', order_date)::DATE,
    customer_id,
    customer_name

ORDER BY
    month,
    monthly_sales DESC;


-- ============================================
-- TEST MONTHLY CUSTOMER REVENUE VIEW
-- ============================================

SELECT *
FROM vw_monthly_customer_revenue
LIMIT 20;


-- ============================================
-- CUSTOMER TYPE SEGMENTATION VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT
    customer_id,
    customer_name,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    CASE
        WHEN COUNT(DISTINCT order_id) = 1
            THEN 'One-Time Customer'

        WHEN COUNT(DISTINCT order_id) BETWEEN 2 AND 5
            THEN 'Repeat Customer'

        WHEN COUNT(DISTINCT order_id) > 5
            THEN 'Loyal Customer'

        ELSE 'Unknown'
    END AS customer_segment

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_sales DESC;


-- ============================================
-- TEST CUSTOMER SEGMENTATION VIEW
-- ============================================

SELECT *
FROM vw_customer_segments
LIMIT 20;


-- ============================================
-- MONTHLY REVENUE GROWTH VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_monthly_revenue_growth AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS active_customers

FROM orders_clean

GROUP BY
    DATE_TRUNC('month', order_date)::DATE

ORDER BY month;


-- ============================================
-- TEST MONTHLY REVENUE GROWTH VIEW
-- ============================================

SELECT *
FROM vw_monthly_revenue_growth;


-- ============================================
-- CUSTOMER RETENTION ANALYSIS VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_retention_analysis AS
SELECT
    customer_id,
    customer_name,

    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(sales)::numeric, 2) AS lifetime_sales,
    ROUND(SUM(profit)::numeric, 2) AS lifetime_profit,

   (MAX(order_date) - MIN(order_date)) AS customer_lifespan_days,
   
    CASE
        WHEN MAX(order_date) >= (
            SELECT MAX(order_date) - INTERVAL '90 days'
            FROM orders_clean
        )
        THEN 'Active Customer'

        ELSE 'Inactive Customer'
    END AS retention_status

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY lifetime_sales DESC;


-- ============================================
-- TEST CUSTOMER RETENTION ANALYSIS VIEW
-- ============================================

SELECT *
FROM vw_customer_retention_analysis
LIMIT 20;


-- ============================================
-- RFM ANALYTICS BASE VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_rfm_base AS
SELECT
    customer_id,
    customer_name,

    MAX(order_date) AS last_order_date,

    (
        SELECT MAX(order_date)
        FROM orders_clean
    ) - MAX(order_date) AS recency_days,

    COUNT(DISTINCT order_id) AS frequency_orders,

    ROUND(SUM(sales)::numeric, 2) AS monetary_value,

    ROUND(SUM(profit)::numeric, 2) AS total_profit

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY monetary_value DESC;


-- ============================================
-- TEST RFM BASE VIEW
-- ============================================

SELECT *
FROM vw_rfm_base
LIMIT 20;


-- ============================================
-- CUSTOMER COHORT ANALYSIS VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_cohorts AS

WITH first_purchase AS (

    SELECT
        customer_id,

        MIN(
            DATE_TRUNC('month', order_date)::DATE
        ) AS cohort_month

    FROM orders_clean

    GROUP BY customer_id
)

SELECT
    fp.cohort_month,

    DATE_TRUNC('month', o.order_date)::DATE AS order_month,

    o.customer_id,

    ROUND(SUM(o.sales)::numeric, 2) AS monthly_sales,
    ROUND(SUM(o.profit)::numeric, 2) AS monthly_profit,

    COUNT(DISTINCT o.order_id) AS monthly_orders

FROM orders_clean o

JOIN first_purchase fp
    ON o.customer_id = fp.customer_id

GROUP BY
    fp.cohort_month,
    DATE_TRUNC('month', o.order_date)::DATE,
    o.customer_id

ORDER BY
    cohort_month,
    order_month;


-- ============================================
-- TEST CUSTOMER COHORT ANALYSIS VIEW
-- ============================================

SELECT *
FROM vw_customer_cohorts
LIMIT 20;


-- ============================================
-- CUSTOMER COHORT SUMMARY VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_cohort_summary AS
SELECT
    cohort_month,
    order_month,

    (
        EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)
    ) * 12
    +
    (
        EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month)
    ) AS cohort_period_month,

    COUNT(DISTINCT customer_id) AS active_customers,

    ROUND(SUM(monthly_sales)::numeric, 2) AS cohort_sales,
    ROUND(SUM(monthly_profit)::numeric, 2) AS cohort_profit

FROM vw_customer_cohorts

GROUP BY
    cohort_month,
    order_month

ORDER BY
    cohort_month,
    cohort_period_month;


-- ============================================
-- TEST CUSTOMER COHORT SUMMARY VIEW
-- ============================================

SELECT *
FROM vw_customer_cohort_summary
LIMIT 50;


-- ============================================
-- CUSTOMER LIFETIME VALUE VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_lifetime_value AS
SELECT
    customer_id,
    customer_name,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(sales)::numeric, 2) AS lifetime_sales,
    ROUND(SUM(profit)::numeric, 2) AS lifetime_profit,

    ROUND(AVG(sales)::numeric, 2) AS avg_order_value,

    ROUND(
        SUM(sales)::numeric /
        NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS revenue_per_order,

    ROUND(
        SUM(profit)::numeric /
        NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS profit_per_order,

    (
        MAX(order_date) - MIN(order_date)
    ) AS customer_lifespan_days,

    ROUND(
        (
            SUM(profit)::numeric /
            NULLIF(COUNT(DISTINCT order_id), 0)
        )
        *
        COUNT(DISTINCT order_id),
        2
    ) AS estimated_clv

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY estimated_clv DESC;


-- ============================================
-- TEST CUSTOMER LIFETIME VALUE VIEW
-- ============================================

SELECT *
FROM vw_customer_lifetime_value
LIMIT 20;


-- ============================================
-- CUSTOMER PROFITABILITY SEGMENTATION VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_profitability_segments AS
SELECT
    customer_id,
    customer_name,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    ROUND(
        SUM(profit)::numeric /
        NULLIF(SUM(sales)::numeric, 0) * 100,
        2
    ) AS profit_margin_pct,

    COUNT(DISTINCT order_id) AS total_orders,

    CASE
        WHEN SUM(profit) >= 5000
            THEN 'High Value'

        WHEN SUM(profit) BETWEEN 1000 AND 4999
            THEN 'Medium Value'

        WHEN SUM(profit) < 1000
            THEN 'Low Value'

        ELSE 'Unclassified'
    END AS profitability_segment

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_profit DESC;


-- ============================================
-- TEST CUSTOMER PROFITABILITY SEGMENTATION VIEW
-- ============================================

SELECT *
FROM vw_customer_profitability_segments
LIMIT 20;

-- ============================================
-- CUSTOMER REVENUE CONCENTRATION VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_revenue_concentration AS
SELECT
    customer_id,
    customer_name,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    ROUND(
        SUM(sales)::numeric /
        (
            SELECT SUM(sales)
            FROM orders_clean
        ) * 100,
        2
    ) AS revenue_contribution_pct,

    ROUND(
        SUM(profit)::numeric /
        NULLIF(
            (
                SELECT SUM(profit)
                FROM orders_clean
            ),
            0
        ) * 100,
        2
    ) AS profit_contribution_pct

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_sales DESC;


-- ============================================
-- TEST CUSTOMER REVENUE CONCENTRATION VIEW
-- ============================================

SELECT *
FROM vw_customer_revenue_concentration
LIMIT 20;


-- ============================================
-- CUSTOMER RISK SEGMENTATION VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_risk_segments AS
SELECT
    customer_id,
    customer_name,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    COUNT(DISTINCT order_id) AS total_orders,

    MAX(order_date) AS last_order_date,

    (
        SELECT MAX(order_date)
        FROM orders_clean
    ) - MAX(order_date) AS days_since_last_order,

    CASE
        WHEN (
            (
                SELECT MAX(order_date)
                FROM orders_clean
            ) - MAX(order_date)
        ) <= 30
            THEN 'Active'

        WHEN (
            (
                SELECT MAX(order_date)
                FROM orders_clean
            ) - MAX(order_date)
        ) BETWEEN 31 AND 90
            THEN 'At Risk'

        WHEN (
            (
                SELECT MAX(order_date)
                FROM orders_clean
            ) - MAX(order_date)
        ) > 90
            THEN 'Churned'

        ELSE 'Unknown'
    END AS customer_risk_status

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_sales DESC;


-- ============================================
-- TEST CUSTOMER RISK SEGMENTATION VIEW
-- ============================================

SELECT *
FROM vw_customer_risk_segments
LIMIT 20;


-- ============================================
-- CUSTOMER GROWTH CLASSIFICATION VIEW
-- ============================================

CREATE OR REPLACE VIEW vw_customer_growth_classification AS
SELECT
    customer_id,
    customer_name,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,

    ROUND(
        SUM(profit)::numeric /
        NULLIF(SUM(sales)::numeric, 0) * 100,
        2
    ) AS profit_margin_pct,

    CASE
        WHEN SUM(sales) >= 10000
             AND COUNT(DISTINCT order_id) >= 10
            THEN 'Strategic Customer'

        WHEN SUM(sales) BETWEEN 5000 AND 9999
            THEN 'Growth Customer'

        WHEN SUM(sales) < 5000
            THEN 'Emerging Customer'

        ELSE 'Unclassified'
    END AS growth_classification

FROM orders_clean

GROUP BY
    customer_id,
    customer_name

ORDER BY total_sales DESC;


-- ============================================
-- TEST CUSTOMER GROWTH CLASSIFICATION VIEW
-- ============================================

SELECT *
FROM vw_customer_growth_classification
LIMIT 20;