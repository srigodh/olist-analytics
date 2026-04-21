WITH products AS (
    SELECT * FROM {{ ref('mart_product_performance') }}
)

SELECT
    category,
    COUNT(DISTINCT product_id)      AS total_products,
    SUM(total_orders)               AS total_orders,
    SUM(total_units_sold)           AS total_units_sold,
    ROUND(SUM(total_revenue), 2)    AS total_revenue,
    ROUND(AVG(avg_price), 2)        AS avg_price,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_orders), 0), 2) AS revenue_per_order

FROM products
GROUP BY category
ORDER BY total_revenue DESC