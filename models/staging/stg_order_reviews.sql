WITH source AS (
    SELECT * FROM {{ source('olist_raw', 'ORDER_REVIEWS') }}
)
SELECT
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    CASE
        WHEN review_score >= 4 THEN 'positive'
        WHEN review_score = 3  THEN 'neutral'
        ELSE 'negative'
    END AS sentiment
FROM source
WHERE review_id IS NOT NULL