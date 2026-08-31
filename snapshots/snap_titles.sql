{% snapshot snap_titles %}

{{
    config(
        target_database=target.database,
        target_schema=target.schema,
        unique_key='title_id',
        strategy='check',
        check_cols=['list_price_usd', 'sunset_date'],
    )
}}

select
    title_id,
    title_name,
    list_price_usd,
    sunset_date
from {{ ref('stg_levelup__titles') }}

{% endsnapshot %}
