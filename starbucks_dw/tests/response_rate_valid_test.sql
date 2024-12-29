{% test response_rate_valid_test(model) %}
SELECT *
    FROM {{ (model) }}
    WHERE response_rate < 0 OR response_rate > 1
{% endtest %}
