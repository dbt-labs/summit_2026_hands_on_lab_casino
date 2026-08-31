with sessions as (

    select * from {{ ref('int_play_sessions_enriched') }}

),

player_summary as (

    select
        player_id,
        count(*) as lifetime_sessions,
        sum(case when is_valid_session then 1 else 0 end) as lifetime_valid_sessions,
        sum(duration_minutes) as lifetime_play_minutes,
        count(distinct title_id) as distinct_titles_played,
        min(session_start_at) as first_session_at,
        max(session_start_at) as last_session_at
    from sessions
    group by 1

),

title_counts as (

    select
        player_id,
        title_id,
        count(*) as sessions_on_title,
        row_number() over (partition by player_id order by count(*) desc, title_id asc) as _title_rank
    from sessions
    group by 1, 2

),

platform_counts as (

    select
        player_id,
        platform,
        count(*) as sessions_on_platform,
        row_number() over (partition by player_id order by count(*) desc, platform asc) as _platform_rank
    from sessions
    group by 1, 2

),

final as (

    select
        player_summary.*,
        title_counts.title_id as favorite_title_id,
        platform_counts.platform as primary_platform
    from player_summary
    left join title_counts
        on player_summary.player_id = title_counts.player_id
        and title_counts._title_rank = 1
    left join platform_counts
        on player_summary.player_id = platform_counts.player_id
        and platform_counts._platform_rank = 1

)

select * from final
