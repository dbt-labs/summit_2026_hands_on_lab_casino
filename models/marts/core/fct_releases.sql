with releases as (

    select * from {{ ref('stg_levelup__releases') }}

),

sessions as (

    select * from {{ ref('int_play_sessions_enriched') }}

),

before_window as (

    select
        releases.release_id,
        count(*) as sessions_before,
        count(distinct sessions.player_id) as active_players_before,
        avg(case when sessions.crashed_flag then 1.0 else 0.0 end) as crash_rate_before,
        avg(sessions.duration_minutes) as avg_session_minutes_before
    from releases
    left join sessions
        on releases.title_id = sessions.title_id
        and sessions.session_start_at >= dateadd('day', -10, releases.released_at)
        and sessions.session_start_at < releases.released_at
    group by 1

),

after_window as (

    select
        releases.release_id,
        count(*) as sessions_after,
        count(distinct sessions.player_id) as active_players_after,
        avg(case when sessions.crashed_flag then 1.0 else 0.0 end) as crash_rate_10d_after,
        avg(sessions.duration_minutes) as avg_session_minutes_after
    from releases
    left join sessions
        on releases.title_id = sessions.title_id
        and sessions.session_start_at >= releases.released_at
        and sessions.session_start_at < dateadd('day', 10, releases.released_at)
    group by 1

),

final as (

    select
        releases.release_id,
        releases.title_id,
        releases.app_version,
        releases.released_at,
        releases.release_type,
        releases.release_notes,
        releases.dev_days_estimated,
        releases.dev_days_actual,
        releases.dev_days_actual - releases.dev_days_estimated as dev_days_variance,
        case when releases.dev_days_estimated > 0
            then (releases.dev_days_actual - releases.dev_days_estimated)::float / releases.dev_days_estimated
        end as dev_days_variance_pct,
        releases.qa_bug_count,
        releases.is_rollback,
        coalesce(before_window.sessions_before, 0) as sessions_before,
        coalesce(after_window.sessions_after, 0) as sessions_after,
        coalesce(after_window.sessions_after, 0) - coalesce(before_window.sessions_before, 0) as session_count_delta,
        before_window.active_players_before,
        after_window.active_players_after,
        before_window.crash_rate_before,
        after_window.crash_rate_10d_after,
        before_window.avg_session_minutes_before,
        after_window.avg_session_minutes_after,
        case when releases.dev_days_estimated > 0
            and (releases.dev_days_actual - releases.dev_days_estimated)::float / releases.dev_days_estimated > 0.2
            then true else false
        end as is_over_budget,
        (
            coalesce(after_window.sessions_after, 0) < coalesce(before_window.sessions_before, 0)
            or coalesce(after_window.crash_rate_10d_after, 0) - coalesce(before_window.crash_rate_before, 0) > 0.05
        ) as made_engagement_worse
    from releases
    left join before_window
        on releases.release_id = before_window.release_id
    left join after_window
        on releases.release_id = after_window.release_id

)

select * from final
