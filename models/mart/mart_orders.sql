WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

customers AS (
    SELECT * FROM {{ ref('stg_customers') }}
),

items AS (
    SELECT
        order_id,
        COUNT(order_item_id)        AS total_items,
        SUM(price)                  AS total_price,
        SUM(freight_value)          AS total_freight,
        SUM(total_item_value)       AS total_order_value
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

payments AS (
    SELECT
        order_id,
        SUM(payment_value)          AS total_payment,
        COUNT(DISTINCT payment_type) AS payment_methods_used,
        MAX(payment_installments)   AS max_installments
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

reviews AS (
    SELECT
        order_id,
        review_score,
        sentiment,
        review_comment_message
    FROM {{ ref('stg_order_reviews') }}
)

SELECT
    o.order_id,
    o.customer_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.delivery_days,
    o.estimated_days,
    o.delivered_on_time,
    i.total_items,
    i.total_price,
    i.total_freight,
    i.total_order_value,
    p.total_payment,
    p.payment_methods_used,
    p.max_installments,
    r.review_score,
    r.sentiment,
    r.review_comment_message,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    DATE_TRUNC('year',  o.order_purchase_timestamp) AS order_year

FROM orders o
LEFT JOIN customers   c ON o.customer_id = c.customer_id
LEFT JOIN items       i ON o.order_id    = i.order_id
LEFT JOIN payments    p ON o.order_id    = p.order_id
LEFT JOIN reviews     r ON o.order_id    = r.order_id