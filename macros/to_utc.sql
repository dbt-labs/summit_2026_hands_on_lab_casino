{% macro to_utc(column_name, source_tz='America/New_York') %}
    convert_timezone('{{ source_tz }}', 'UTC', {{ column_name }})
{% endmacro %}
