{% macro signed_net_amount(amount_column, transaction_type_column) %}
    case
        when {{ transaction_type_column }} in ('refund', 'chargeback') then -1 * {{ amount_column }}
        else {{ amount_column }}
    end
{% endmacro %}
