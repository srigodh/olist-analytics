WITH orders AS (
    SELECT * FROM {{ ref('mart_orders') }}
)

SELECT
    order_month,
    customer_state,
    order_status,
    COUNT(DISTINCT order_id)        AS total_orders,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    ROUND(SUM(total_payment), 2)    AS total_revenue,
    ROUND(AVG(total_payment), 2)    AS avg_order_value,
    ROUND(AVG(delivery_days), 2)    AS avg_delivery_days,
    ROUND(AVG(review_score), 2)     AS avg_review_score,
    COUNT(CASE WHEN delivered_on_time 
          THEN 1 END)               AS on_time_deliveries,
    ROUND(100.0 * COUNT(
        CASE WHEN delivered_on_time THEN 1 END
    ) / NULLIF(COUNT(order_id), 0), 2) AS on_time_pct

FROM orders
GROUP BY order_month, customer_state, order_status
ORDER BY order_month DESC