with high_scores as (

    select * from {{ ref('stg_levelup__high_scores') }}

),

ranked as (

    select
        *,
        case when not flagged_for_cheating then
            rank() over (
                partition by leaderboard_id
                order by case when not flagged_for_cheating then score_value end desc
            )
        end as leaderboard_rank,
        case when not flagged_for_cheating then
            percent_rank() over (
                partition by leaderboard_id
                order by case when not flagged_for_cheating then score_value end desc
            )
        end as leaderboard_percentile
    from high_scores

)

select
    score_id,
    player_id,
    title_id,
    leaderboard_id,
    score_value,
    submitted_at,
    is_verified,
    flagged_for_cheating,
    leaderboard_rank,
    leaderboard_percentile
from ranked
