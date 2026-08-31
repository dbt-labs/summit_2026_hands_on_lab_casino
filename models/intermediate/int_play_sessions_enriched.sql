with play_sessions as (

    select * from {{ ref('stg_levelup__play_sessions') }}

),

players as (

    select player_id, registered_at
    from {{ ref('stg_levelup__players') }}

),

releases as (

    select release_id, title_id, app_version, released_at
    from {{ ref('stg_levelup__releases') }}

),

sessions_with_players as (

    select
        play_sessions.*,
        players.registered_at as player_registered_at
    from play_sessions
    left join players
        on play_sessions.player_id = players.player_id

),

release_in_effect as (

    select
        sessions_with_players.session_id,
        releases.app_version as release_in_effect,
        row_number() over (
            partition by sessions_with_players.session_id
            order by releases.released_at desc
        ) as _release_rank
    from sessions_with_players
    left join releases
        on sessions_with_players.title_id = releases.title_id
        and releases.released_at <= sessions_with_players.session_start_at

),

final as (

    select
        sessions_with_players.session_id,
        sessions_with_players.player_id,
        sessions_with_players.title_id,
        sessions_with_players.platform,
        sessions_with_players.session_start_at,
        sessions_with_players.session_end_at,
        sessions_with_players.duration_seconds,
        sessions_with_players.duration_seconds / 60.0 as duration_minutes,
        sessions_with_players.session_end_at is not null
            and sessions_with_players.duration_seconds between 1 and 21600 as is_valid_session,
        sessions_with_players.device_model,
        coalesce(release_in_effect.release_in_effect, sessions_with_players.app_version) as app_version_in_effect,
        sessions_with_players.country_code,
        sessions_with_players.levels_completed,
        sessions_with_players.crashed_flag,
        sessions_with_players.network_type,
        date_trunc('month', sessions_with_players.player_registered_at) as registration_cohort_month,
        date_trunc('month', sessions_with_players.session_start_at) as session_month,
        date_trunc('week', sessions_with_players.session_start_at) as session_week,
        floor(
            datediff('day', sessions_with_players.player_registered_at, sessions_with_players.session_start_at) / 7
        ) as week_offset_from_registration,
        dayofweek(sessions_with_players.session_start_at) in (0, 6) as is_weekend_session,
        sessions_with_players.source_synced_at
    from sessions_with_players
    left join release_in_effect
        on sessions_with_players.session_id = release_in_effect.session_id
        and release_in_effect._release_rank = 1

)

select * from final
