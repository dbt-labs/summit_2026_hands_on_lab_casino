with transactions as (

    select * from {{ ref('stg_levelup__transactions') }}

),

final as (

    select
        transaction_id,
        player_id,
        title_id,
        platform,
        sku_id,
        transaction_at,
        transaction_at_local,
        transaction_type,
        gross_amount_usd,
        platform_fee_usd,
        {{ signed_net_amount('gross_amount_usd', 'transaction_type') }} as net_amount_usd,
        {{ signed_net_amount('gross_amount_usd', 'transaction_type') }}
            - {{ signed_net_amount('platform_fee_usd', 'transaction_type') }} as studio_net_revenue_usd,
        case
            when transaction_type in ('iap', 'season_pass') then 'live_service'
            when transaction_type in ('premium_purchase', 'dlc') then 'catalog'
            when transaction_type in ('refund', 'chargeback') then 'reversal'
        end as revenue_stream_group,
        transaction_type in ('iap', 'season_pass') as is_live_service_revenue,
        currency_code,
        local_amount,
        payment_method,
        is_first_purchase,
        source_synced_at
    from transactions

)

select * from final
