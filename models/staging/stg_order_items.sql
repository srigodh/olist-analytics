WITH source AS (
    SELECT * FROM {{ source('olist_raw', 'ORDER_ITEMS') }}
)
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,
    price + freight_value AS total_item_value
FROM source
WHERE order_id IS NOT NULL
