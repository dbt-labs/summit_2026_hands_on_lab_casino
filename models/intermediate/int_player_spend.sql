with transactions as (

    select * from {{ ref('int_transactions') }}

),

aggregated as (

    select
        player_id,
        sum(net_amount_usd) as lifetime_net_revenue_usd,
        sum(studio_net_revenue_usd) as lifetime_studio_net_usd,
        sum(case when transaction_type in ('iap', 'season_pass', 'refund', 'chargeback')
            then net_amount_usd else 0 end) as live_service_net_usd,
        sum(case when transaction_type = 'premium_purchase' then net_amount_usd else 0 end) as premium_net_usd,
        sum(case when transaction_type = 'dlc' then net_amount_usd else 0 end) as dlc_net_usd,
        sum(case when transaction_type = 'iap' then net_amount_usd else 0 end) as iap_net_usd,
        sum(case when transaction_type = 'season_pass' then net_amount_usd else 0 end) as season_pass_net_usd,
        sum(case when transaction_type in ('refund', 'chargeback') then gross_amount_usd else 0 end) as refunded_gross_usd,
        count(*) as lifetime_transactions,
        min(case when transaction_type in ('premium_purchase', 'iap', 'season_pass', 'dlc')
            then transaction_at end) as first_purchase_at
    from transactions
    group by 1

),

final as (

    select
        *,
        live_service_net_usd > 0 as is_payer,
        case
            when live_service_net_usd >= {{ var('payer_segment_whale_threshold_usd') }} then 'whale'
            when live_service_net_usd >= {{ var('payer_segment_dolphin_threshold_usd') }} then 'dolphin'
            when live_service_net_usd >= {{ var('payer_segment_minnow_threshold_usd') }} then 'minnow'
            else 'non_payer'
        end as payer_segment
    from aggregated

)

select * from final
