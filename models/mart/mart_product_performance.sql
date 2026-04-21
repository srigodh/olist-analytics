WITH items AS (
    SELECT * FROM {{ ref('stg_order_items') }}
),

products AS (
    SELECT * FROM {{ ref('stg_products') }}
),

translations AS (
    SELECT * FROM {{ ref('stg_category_translations') }}
),

reviews AS (
    SELECT * FROM {{ ref('stg_order_reviews') }}
)

SELECT
    p.product_id,
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'Unknown')                 AS category,
    COUNT(DISTINCT i.order_id)          AS total_orders,
    COUNT(i.order_item_id)              AS total_units_sold,
    ROUND(SUM(i.price), 2)              AS total_revenue,
    ROUND(AVG(i.price), 2)              AS avg_price,
    ROUND(AVG(r.review_score), 2)       AS avg_review_score,
    p.product_weight_g,
    p.product_photos_qty

FROM products p
LEFT JOIN translations t ON p.product_category_name = t.product_category_name
LEFT JOIN items        i ON p.product_id             = i.product_id
LEFT JOIN reviews      r ON i.order_id               = r.order_id

GROUP BY
    p.product_id,
    t.product_category_name_english,
    p.product_category_name,
    p.product_weight_g,
    p.product_photos_qty