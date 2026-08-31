with players as (

    select * from {{ ref('stg_levelup__players') }}

),

activity as (

    select * from {{ ref('int_player_activity') }}

),

spend as (

    select * from {{ ref('int_player_spend') }}

),

titles as (

    select title_id, title_name from {{ ref('stg_levelup__titles') }}

),

final as (

    select
        players.player_id,
        players.registered_at,
        date_trunc('month', players.registered_at) as registration_cohort_month,
        players.country_code,
        players.platform_registered_on,
        players.acquisition_channel,
        players.acquisition_campaign_id,
        date_part('year', '{{ var("analysis_as_of_date") }}'::date) - players.birth_year as age_years,
        players.account_status,
        players.last_login_at,
        coalesce(activity.lifetime_sessions, 0) as lifetime_sessions,
        coalesce(activity.lifetime_valid_sessions, 0) as lifetime_valid_sessions,
        coalesce(activity.lifetime_play_minutes, 0) as lifetime_play_minutes,
        coalesce(activity.distinct_titles_played, 0) as distinct_titles_played,
        activity.first_session_at,
        activity.last_session_at,
        activity.favorite_title_id,
        titles.title_name as favorite_title_name,
        activity.primary_platform,
        coalesce(spend.lifetime_net_revenue_usd, 0) as lifetime_net_revenue_usd,
        coalesce(spend.lifetime_studio_net_usd, 0) as lifetime_studio_net_usd,
        coalesce(spend.live_service_net_usd, 0) as live_service_net_usd,
        coalesce(spend.lifetime_transactions, 0) as lifetime_transactions,
        spend.first_purchase_at,
        coalesce(spend.is_payer, false) as is_payer,
        coalesce(spend.payer_segment, 'non_payer') as payer_segment,
        datediff(
            'day',
            coalesce(activity.last_session_at, players.registered_at),
            '{{ var("analysis_as_of_date") }}'::date
        ) > {{ var('churn_days_threshold') }} as is_churned
    from players
    left join activity
        on players.player_id = activity.player_id
    left join spend
        on players.player_id = spend.player_id
    left join titles
        on activity.favorite_title_id = titles.title_id

)

select
    player_id,
    registered_at,
    registration_cohort_month,
    country_code,
    platform_registered_on,
    acquisition_channel,
    acquisition_campaign_id,
    age_years,
    account_status,
    last_login_at,
    lifetime_sessions,
    lifetime_valid_sessions,
    lifetime_play_minutes,
    distinct_titles_played,
    first_session_at,
    last_session_at,
    favorite_title_id,
    favorite_title_name,
    primary_platform,
    lifetime_net_revenue_usd,
    lifetime_studio_net_usd,
    live_service_net_usd,
    lifetime_transactions,
    first_purchase_at,
    is_payer,
    payer_segment,
    is_churned
from final
