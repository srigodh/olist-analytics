
WITH source AS (
    SELECT * FROM {{ source('olist_raw', 'ORDERS') }}
)

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    DATEDIFF('day',
        order_purchase_timestamp,
        order_delivered_customer_date
    ) AS delivery_days,
    DATEDIFF('day',
        order_purchase_timestamp,
        order_estimated_delivery_date
    ) AS estimated_days,
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
        THEN TRUE ELSE FALSE
    END AS delivered_on_time

FROM source
WHERE order_id IS NOT NULL