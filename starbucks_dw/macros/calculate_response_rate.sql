{% macro calculate_response_rate(success_column, total_column) %}
    ROUND(
        SUM(COALESCE({{ success_column }}, 0))::DECIMAL / NULLIF(SUM(COALESCE({{ total_column }}, 0)), 0),
        4
    )
{% endmacro %}
