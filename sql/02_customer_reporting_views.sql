CREATE OR REPLACE VIEW vw_category_performance AS
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM orders_clean
GROUP BY category, sub_category;


CREATE OR REPLACE VIEW vw_loss_products AS
SELECT
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders_clean
GROUP BY product_name, category, sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;

CREATE OR REPLACE VIEW vw_region_performance AS
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders_clean
GROUP BY region
ORDER BY total_sales DESC;

CREATE OR REPLACE VIEW vw_customer_performance AS
SELECT
    customer_name,
    segment,
    region,

    ROUND(SUM(sales), 2) AS total_sales,

    ROUND(SUM(profit), 2) AS total_profit,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(AVG(sales), 2) AS avg_order_value

FROM orders_clean

GROUP BY customer_name, segment, region

ORDER BY total_sales DESC;

CREATE OR REPLACE VIEW vw_discount_analysis AS
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low Discount'
        WHEN discount <= 0.5 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_band,

    category,
    sub_category,

    ROUND(SUM(sales), 2) AS total_sales,

    ROUND(SUM(profit), 2) AS total_profit,

    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct,

    COUNT(DISTINCT order_id) AS total_orders

FROM orders_clean

GROUP BY
    discount_band,
    category,
    sub_category

ORDER BY total_profit ASC;