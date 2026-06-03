DROP TABLE IF EXISTS orders_clean;

CREATE TABLE orders_clean AS
SELECT
    row_id::int AS row_id,
    order_id,
    TO_DATE(order_date, 'MM/DD/YYYY') AS order_date,
    TO_DATE(ship_date, 'MM/DD/YYYY') AS ship_date,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales::numeric AS sales,
    quantity::int AS quantity,
    discount::numeric AS discount,
    profit::numeric AS profit
FROM orders_raw;