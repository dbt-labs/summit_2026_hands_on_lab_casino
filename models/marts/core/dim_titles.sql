with titles as (

    select * from {{ ref('stg_levelup__titles') }}

),

activity as (

    select * from {{ ref('int_title_activity') }}

),

platform_counts as (

    select
        title_id,
        count(distinct platform_id) as platform_count
    from {{ ref('stg_levelup__title_platforms') }}
    group by 1

),

final as (

    select
        titles.title_id,
        titles.title_name,
        titles.genre,
        titles.monetization_model,
        titles.list_price_usd,
        titles.launch_date,
        titles.is_live_service,
        titles.sunset_date,
        titles.dev_team,
        titles.engine,
        titles.esrb_rating,
        coalesce(platform_counts.platform_count, 0) as platform_count,
        coalesce(activity.lifetime_sessions, 0) as lifetime_sessions,
        coalesce(activity.lifetime_players, 0) as lifetime_players,
        coalesce(activity.sessions_last_60d, 0) as sessions_last_60d,
        coalesce(activity.active_players_last_90d, 0) as active_players_last_90d,
        activity.last_session_at,
        activity.days_since_last_session,
        activity.avg_review_rating,
        coalesce(activity.review_count, 0) as review_count,
        activity.recommend_rate,
        datediff('day', titles.launch_date, '{{ var("analysis_as_of_date") }}'::date) as days_since_launch,
        case
            when datediff('day', titles.launch_date, '{{ var("analysis_as_of_date") }}'::date) <= 90
                then 'launch_window'
            when activity.days_since_last_session is not null
                and activity.days_since_last_session > 60
                and datediff('day', titles.launch_date, '{{ var("analysis_as_of_date") }}'::date) > 365
                then 'sunset_candidate'
            when datediff('day', titles.launch_date, '{{ var("analysis_as_of_date") }}'::date) <= 365
                then 'growth'
            when coalesce(activity.active_players_last_90d, 0) >= {{ var('mature_active_players_threshold') }}
                then 'mature'
            else 'declining'
        end as lifecycle_stage
    from titles
    left join activity
        on titles.title_id = activity.title_id
    left join platform_counts
        on titles.title_id = platform_counts.title_id

)

select * from final
