WITH source AS (
    SELECT * FROM {{ source('olist_raw', 'CATEGORY_NAME_TRANSLATION') }}
)
SELECT
    product_category_name,
    product_category_name_english
FROM source