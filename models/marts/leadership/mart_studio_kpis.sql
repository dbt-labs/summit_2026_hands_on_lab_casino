with sessions as (

    select * from {{ ref('fct_play_sessions') }}

),

transactions as (

    select * from {{ ref('fct_transactions') }}

),

players as (

    select * from {{ ref('dim_players') }}

),

titles as (

    select * from {{ ref('dim_titles') }}

),

marketing as (

    select * from {{ ref('stg_levelup__marketing_spend') }}

),

monthly_sessions as (

    select
        session_month as month,
        count(distinct player_id) as monthly_active_players,
        count(*) as session_count
    from sessions
    group by 1

),

monthly_registrations as (

    select
        date_trunc('month', registered_at) as month,
        count(*) as new_registrations
    from players
    group by 1

),

monthly_revenue as (

    select
        date_trunc('month', transaction_at) as month,
        sum(net_amount_usd) as net_revenue_usd,
        sum(studio_net_revenue_usd) as studio_net_revenue_usd,
        sum(case when transaction_type in ('refund', 'chargeback') then gross_amount_usd else 0 end) as refund_gross_usd,
        sum(case when revenue_stream_group = 'live_service' then net_amount_usd else 0 end) as live_service_net_usd,
        sum(case when revenue_stream_group = 'catalog' then net_amount_usd else 0 end) as catalog_net_usd,
        count(distinct case when is_live_service_revenue then player_id end) as paying_players
    from transactions
    group by 1

),

monthly_title_revenue as (

    select
        date_trunc('month', transaction_at) as month,
        title_id,
        sum(net_amount_usd) as title_net_revenue
    from transactions
    group by 1, 2

),

monthly_player_revenue as (

    select
        date_trunc('month', transaction_at) as month,
        player_id,
        sum(net_amount_usd) as player_net_revenue
    from transactions
    group by 1, 2

),

top_title as (

    select
        month,
        title_net_revenue as top_title_revenue,
        row_number() over (partition by month order by title_net_revenue desc) as _rank
    from monthly_title_revenue

),

top_player as (

    select
        month,
        player_net_revenue as top_player_revenue,
        row_number() over (partition by month order by player_net_revenue desc) as _rank
    from monthly_player_revenue

),

monthly_marketing as (

    select
        date_trunc('month', week_start_date) as month,
        sum(spend_usd) as marketing_spend_usd,
        sum(installs) as installs
    from marketing
    group by 1

),

portfolio_health as (

    select
        count(*) as title_count,
        count(case when lifecycle_stage = 'launch_window' then 1 end) as titles_in_launch_window,
        count(case when lifecycle_stage = 'growth' then 1 end) as titles_in_growth,
        count(case when lifecycle_stage = 'mature' then 1 end) as titles_mature,
        count(case when lifecycle_stage = 'declining' then 1 end) as titles_declining,
        count(case when lifecycle_stage = 'sunset_candidate' then 1 end) as titles_sunset_candidate
    from titles

),

final as (

    select
        monthly_sessions.month,
        monthly_sessions.monthly_active_players,
        monthly_sessions.session_count,
        coalesce(monthly_registrations.new_registrations, 0) as new_registrations,
        monthly_revenue.net_revenue_usd,
        monthly_revenue.studio_net_revenue_usd,
        monthly_revenue.refund_gross_usd,
        monthly_revenue.live_service_net_usd,
        monthly_revenue.catalog_net_usd,
        monthly_revenue.paying_players,
        monthly_revenue.paying_players::float / nullif(monthly_sessions.monthly_active_players, 0) as payer_conversion_rate,
        monthly_revenue.net_revenue_usd / nullif(monthly_sessions.monthly_active_players, 0) as arpu_usd,
        top_title.top_title_revenue / nullif(monthly_revenue.net_revenue_usd, 0) as top_title_revenue_share,
        top_player.top_player_revenue / nullif(monthly_revenue.net_revenue_usd, 0) as top_player_revenue_share,
        monthly_marketing.marketing_spend_usd,
        monthly_marketing.installs as marketing_installs,
        monthly_marketing.marketing_spend_usd / nullif(monthly_marketing.installs, 0) as blended_cac_usd,
        portfolio_health.title_count,
        portfolio_health.titles_in_launch_window,
        portfolio_health.titles_in_growth,
        portfolio_health.titles_mature,
        portfolio_health.titles_declining,
        portfolio_health.titles_sunset_candidate
    from monthly_sessions
    left join monthly_registrations
        on monthly_sessions.month = monthly_registrations.month
    left join monthly_revenue
        on monthly_sessions.month = monthly_revenue.month
    left join top_title
        on monthly_sessions.month = top_title.month
        and top_title._rank = 1
    left join top_player
        on monthly_sessions.month = top_player.month
        and top_player._rank = 1
    left join monthly_marketing
        on monthly_sessions.month = monthly_marketing.month
    cross join portfolio_health

)

select * from final
order by month
