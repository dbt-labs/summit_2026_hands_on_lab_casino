-- A session can't occur before the player registered.
select
    sessions.session_id,
    sessions.player_id,
    sessions.session_start_at,
    players.registered_at
from {{ ref('stg_levelup__play_sessions') }} as sessions
inner join {{ ref('stg_levelup__players') }} as players
    on sessions.player_id = players.player_id
where sessions.session_start_at < players.registered_at
