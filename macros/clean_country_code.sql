{% macro clean_country_code(column_name) %}
    nullif(upper(trim({{ column_name }})), '')
{% endmacro %}
