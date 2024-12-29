{{
  config(
    materialized = 'table'
  )
}}


WITH customer_data AS (
    SELECT
        c.customer_id,
        c.gender,
        c.age,
        c.income,
        c.subscribed_date,
        CASE
            WHEN c.income < 25000 THEN 'Low Income (<25k)'
            WHEN c.income BETWEEN 25000 AND 75000 THEN 'Middle Income (25k-75k)'
            WHEN c.income > 75000 THEN 'High Income (>75k)'
            ELSE 'Unknown'
        END AS income_segment,
/* Considering that the sample contains no customers under the age of 18, the age segmentation only
includes groups for ages 18 and above, as it is likely that all customers are 18 years or older. */
        CASE
            WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
            WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
            WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
            WHEN c.age BETWEEN 46 AND 55 THEN '46-55'
            WHEN c.age > 55 THEN '55+'
            ELSE 'Unknown'
        END AS age_group,
/* Subscription duration segmentation
The most recent date in the dataset is 2018, so without detailed segmentation, most customers would be
grouped into a single segment ("More than 5 years"), reducing the utility of the analysis.
This granular segmentation captures differences in behavior based on subscription duration.
 */
        CASE
            WHEN DATE_PART('year', AGE(CURRENT_DATE, c.subscribed_date)) <= 1 THEN 'Less than 1 year'
            WHEN DATE_PART('year', AGE(CURRENT_DATE, c.subscribed_date)) BETWEEN 2 AND 4 THEN '1-4 years'
            WHEN DATE_PART('year', AGE(CURRENT_DATE, c.subscribed_date)) BETWEEN 5 AND 7 THEN '5-7 years'
            WHEN DATE_PART('year', AGE(CURRENT_DATE, c.subscribed_date)) BETWEEN 8 AND 10 THEN '8-10 years'
            WHEN DATE_PART('year', AGE(CURRENT_DATE, c.subscribed_date)) > 10 THEN 'More than 10 years'
            ELSE 'Unknown'
        END AS subscription_duration_group
    FROM {{ ref('dim_customer') }} c
),
offer_data AS (
    SELECT
        ct.customer_id,
        o.offer_type,
        COUNT(ct.offer_id) AS total_offers_received,
        SUM(CASE WHEN ct.transaction_status = 'completed' THEN 1 ELSE 0 END) AS sucessful_response
    FROM {{ ref('dim_offer') }} o
    LEFT JOIN {{ ref('fct_customer_transactions') }} ct ON o.offer_id=ct.offer_id
    GROUP BY ct.customer_id, o.offer_type
)
SELECT
    c.gender,
    c.income_segment,
    c.age_group,
    c.subscription_duration_group,
    o.offer_type,
    {{ calculate_response_rate('o.sucessful_response', 'o.total_offers_received') }} AS response_rate
FROM customer_data c
INNER JOIN offer_data o ON c.customer_id = o.customer_id
GROUP BY c.gender, c.income_segment, c.age_group, c.subscription_duration_group, o.offer_type
order by response_rate desc
