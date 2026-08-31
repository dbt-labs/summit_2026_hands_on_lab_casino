with sessions as (

    select * from {{ ref('int_play_sessions_enriched') }}

),

reviews as (

    select * from {{ ref('stg_levelup__reviews') }}

),

session_summary as (

    select
        title_id,
        count(*) as lifetime_sessions,
        count(distinct player_id) as lifetime_players,
        sum(case when session_start_at >= dateadd('day', -60, '{{ var("analysis_as_of_date") }}'::date)
            then 1 else 0 end) as sessions_last_60d,
        count(distinct case when session_start_at >= dateadd('day', -90, '{{ var("analysis_as_of_date") }}'::date)
            then player_id end) as active_players_last_90d,
        max(session_start_at) as last_session_at
    from sessions
    group by 1

),

review_summary as (

    select
        title_id,
        avg(rating) as avg_review_rating,
        count(*) as review_count,
        avg(case when is_recommended then 1.0 else 0.0 end) as recommend_rate
    from reviews
    group by 1

),

final as (

    select
        session_summary.title_id,
        session_summary.lifetime_sessions,
        session_summary.lifetime_players,
        session_summary.sessions_last_60d,
        session_summary.active_players_last_90d,
        session_summary.last_session_at,
        datediff('day', session_summary.last_session_at, '{{ var("analysis_as_of_date") }}'::date) as days_since_last_session,
        review_summary.avg_review_rating,
        coalesce(review_summary.review_count, 0) as review_count,
        review_summary.recommend_rate
    from session_summary
    left join review_summary
        on session_summary.title_id = review_summary.title_id

)

select * from final
