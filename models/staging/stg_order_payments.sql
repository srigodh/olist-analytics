WITH source AS (
    SELECT * FROM {{ source('olist_raw', 'ORDER_PAYMENTS') }}
)
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM source
WHERE order_id IS NOT NULL