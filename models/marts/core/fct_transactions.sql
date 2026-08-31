with transactions as (

    select * from {{ ref('int_transactions') }}

)

select
    transaction_id,
    player_id,
    title_id,
    platform,
    sku_id,
    transaction_at,
    transaction_at_local,
    transaction_type,
    revenue_stream_group,
    is_live_service_revenue,
    gross_amount_usd,
    platform_fee_usd,
    net_amount_usd,
    studio_net_revenue_usd,
    currency_code,
    local_amount,
    payment_method,
    is_first_purchase
from transactions
