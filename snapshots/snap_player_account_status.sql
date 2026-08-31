{% snapshot snap_player_account_status %}

{{
    config(
        target_database=target.database,
        target_schema=target.schema,
        unique_key='player_id',
        strategy='check',
        check_cols=['account_status'],
    )
}}

select
    player_id,
    account_status,
    last_login_at
from {{ ref('stg_levelup__players') }}

{% endsnapshot %}
