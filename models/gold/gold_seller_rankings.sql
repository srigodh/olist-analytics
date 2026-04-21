WITH sellers AS (
    SELECT * FROM {{ ref('mart_seller_performance') }}
)

SELECT
    seller_id,
    seller_city,
    seller_state,
    total_orders,
    total_revenue,
    avg_review_score,
    on_time_pct,
    RANK() OVER (ORDER BY total_revenue DESC)     AS revenue_rank,
    RANK() OVER (ORDER BY avg_review_score DESC)  AS rating_rank,
    RANK() OVER (ORDER BY on_time_pct DESC)       AS delivery_rank,
    CASE
        WHEN avg_review_score >= 4.5
         AND on_time_pct >= 90
         AND total_orders >= 50  THEN 'Elite'
        WHEN avg_review_score >= 4.0
         AND on_time_pct >= 80   THEN 'Strong'
        WHEN avg_review_score >= 3.0 THEN 'Average'
        ELSE 'Needs Improvement'
    END                                           AS seller_tier

FROM sellers
WHERE total_orders > 0
ORDER BY total_revenue DESC