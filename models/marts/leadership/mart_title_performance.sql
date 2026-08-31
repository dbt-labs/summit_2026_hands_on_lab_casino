with titles as (

    select * from {{ ref('dim_titles') }}

),

sessions as (

    select * from {{ ref('fct_play_sessions') }}

),

transactions as (

    select * from {{ ref('fct_transactions') }}

),

reviews as (

    select * from {{ ref('stg_levelup__reviews') }}

),

months as (

    select distinct month_start_date as month
    from {{ ref('dim_dates') }}
    where is_within_history_window

),

title_month_spine as (

    select
        titles.title_id,
        titles.title_name,
        titles.monetization_model,
        months.month
    from titles
    cross join months
    where months.month >= date_trunc('month', titles.launch_date)

),

monthly_sessions as (

    select
        title_id,
        session_month as month,
        count(distinct player_id) as monthly_active_players,
        count(*) as session_count
    from sessions
    group by 1, 2

),

monthly_revenue as (

    select
        title_id,
        date_trunc('month', transaction_at) as month,
        sum(net_amount_usd) as net_revenue_usd,
        count(distinct case when is_live_service_revenue then player_id end) as paying_players,
        count(distinct player_id) as transacting_players
    from transactions
    group by 1, 2

),

monthly_reviews as (

    select
        title_id,
        date_trunc('month', reviewed_at) as month,
        avg(rating) as avg_review_rating
    from reviews
    group by 1, 2

),

joined as (

    select
        title_month_spine.title_id,
        title_month_spine.title_name,
        title_month_spine.monetization_model,
        title_month_spine.month,
        coalesce(monthly_sessions.monthly_active_players, 0) as monthly_active_players,
        coalesce(monthly_sessions.session_count, 0) as session_count,
        coalesce(monthly_revenue.net_revenue_usd, 0) as net_revenue_usd,
        monthly_revenue.paying_players,
        case when monthly_sessions.monthly_active_players > 0
            then monthly_revenue.paying_players::float / monthly_sessions.monthly_active_players
        end as payer_conversion_rate,
        case when monthly_sessions.monthly_active_players > 0
            then monthly_revenue.net_revenue_usd / monthly_sessions.monthly_active_players
        end as arpu_usd,
        case when monthly_revenue.paying_players > 0
            then monthly_revenue.net_revenue_usd / monthly_revenue.paying_players
        end as arppu_usd,
        monthly_reviews.avg_review_rating,
        monthly_sessions.monthly_active_players >= {{ var('mart_min_monthly_active_players') }} as has_sufficient_volume
    from title_month_spine
    left join monthly_sessions
        on title_month_spine.title_id = monthly_sessions.title_id
        and title_month_spine.month = monthly_sessions.month
    left join monthly_revenue
        on title_month_spine.title_id = monthly_revenue.title_id
        and title_month_spine.month = monthly_revenue.month
    left join monthly_reviews
        on title_month_spine.title_id = monthly_reviews.title_id
        and title_month_spine.month = monthly_reviews.month

),

final as (

    select
        *,
        monthly_active_players - lag(monthly_active_players) over (
            partition by title_id order by month
        ) as map_mom_delta,
        net_revenue_usd - lag(net_revenue_usd) over (
            partition by title_id order by month
        ) as net_revenue_mom_delta
    from joined

)

select * from final
order by title_id, month
