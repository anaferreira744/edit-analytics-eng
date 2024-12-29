{{
  config(
    materialized = 'table'
  )
}}


WITH channel_analysis AS (
    SELECT
        t.offer_id,
        t.offer_channel,
        t.offer_type,
        COUNT(t.offer_id) AS total_offers_received,
        SUM(CASE WHEN t.transaction_status = 'completed' THEN 1 ELSE 0 END) AS successful_responses
    FROM {{ ref('fct_offer_transactions') }} t
    GROUP BY t.offer_id, t.offer_channel, t.offer_type
)

SELECT
    offer_channel,
    offer_type,
    SUM(COALESCE(successful_responses, 0)) as sucessful_response,
    SUM(COALESCE(total_offers_received, 0)) as total_offers_received,
    {{ calculate_response_rate('successful_responses', 'total_offers_received') }} AS response_rate
FROM channel_analysis
GROUP BY offer_channel, offer_type
ORDER BY response_rate DESC
