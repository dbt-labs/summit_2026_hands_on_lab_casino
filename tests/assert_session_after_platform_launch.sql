-- A session can't occur before its title launched on the platform it was played on.
select
    sessions.session_id,
    sessions.title_id,
    sessions.platform,
    sessions.session_start_at,
    title_platforms.platform_launch_date
from {{ ref('stg_levelup__play_sessions') }} as sessions
inner join {{ ref('stg_levelup__platforms') }} as platforms
    on sessions.platform = platforms.platform_name
inner join {{ ref('stg_levelup__title_platforms') }} as title_platforms
    on sessions.title_id = title_platforms.title_id
    and platforms.platform_id = title_platforms.platform_id
where sessions.session_start_at < title_platforms.platform_launch_date
