WITH items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

reviews AS (
    SELECT * FROM {{ ref('stg_order_reviews') }}
),

sellers AS (
    SELECT * FROM {{ ref('stg_sellers') }}
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT i.order_id)          AS total_orders,
    COUNT(i.order_item_id)              AS total_items_sold,
    ROUND(SUM(i.price), 2)              AS total_revenue,
    ROUND(AVG(i.price), 2)              AS avg_item_price,
    ROUND(SUM(i.freight_value), 2)      AS total_freight_charged,
    ROUND(AVG(r.review_score), 2)       AS avg_review_score,
    COUNT(CASE WHEN r.review_score >= 4
          THEN 1 END)                   AS positive_reviews,
    COUNT(CASE WHEN r.review_score <= 2
          THEN 1 END)                   AS negative_reviews,
    COUNT(CASE WHEN o.delivered_on_time = TRUE
          THEN 1 END)                   AS on_time_deliveries,
    ROUND(100.0 * COUNT(
        CASE WHEN o.delivered_on_time = TRUE THEN 1 END
    ) / NULLIF(COUNT(DISTINCT i.order_id), 0), 2) AS on_time_pct

FROM sellers s
LEFT JOIN items   i ON s.seller_id = i.seller_id
LEFT JOIN orders  o ON i.order_id  = o.order_id
LEFT JOIN reviews r ON i.order_id  = r.order_id

GROUP BY s.seller_id, s.seller_city, s.seller_state