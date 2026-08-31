with sessions as (

    select * from {{ ref('int_play_sessions_enriched') }}

)

select
    session_id,
    player_id,
    title_id,
    platform,
    session_start_at,
    session_end_at,
    duration_seconds,
    duration_minutes,
    is_valid_session,
    device_model,
    app_version_in_effect,
    country_code,
    levels_completed,
    crashed_flag,
    network_type,
    registration_cohort_month,
    session_month,
    session_week,
    week_offset_from_registration,
    is_weekend_session
from sessions
