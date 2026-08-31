with releases as (

    select * from {{ ref('fct_releases') }}

),

transactions as (

    select * from {{ ref('fct_transactions') }}

),

revenue_after as (

    select
        releases.release_id,
        sum(transactions.net_amount_usd) as net_revenue_10d_after
    from releases
    left join transactions
        on releases.title_id = transactions.title_id
        and transactions.transaction_at >= releases.released_at
        and transactions.transaction_at < dateadd('day', 10, releases.released_at)
    group by 1

),

final as (

    select
        releases.*,
        revenue_after.net_revenue_10d_after,
        revenue_after.net_revenue_10d_after / nullif(releases.active_players_after, 0)
            as net_revenue_per_active_player_after,
        (
            releases.made_engagement_worse
            or coalesce(releases.crash_rate_10d_after, 0) > 0.15
            or coalesce(releases.dev_days_variance_pct, 0) > 0.3
        ) as regressed_release
    from releases
    left join revenue_after
        on releases.release_id = revenue_after.release_id

)

select * from final
order by title_id, released_at
