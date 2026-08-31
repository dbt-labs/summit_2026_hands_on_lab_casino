with high_scores as (

    select * from {{ ref('fct_high_scores') }}

),

best_legit as (

    select
        player_id,
        title_id,
        leaderboard_id,
        max(score_value) as best_score
    from high_scores
    where not flagged_for_cheating
    group by 1, 2, 3

),

ranked as (

    select
        *,
        rank() over (partition by leaderboard_id order by best_score desc) as leaderboard_rank,
        percent_rank() over (partition by leaderboard_id order by best_score desc) as leaderboard_percentile,
        rank() over (partition by title_id order by best_score desc) as title_rank
    from best_legit

),

flagged as (

    select
        player_id,
        leaderboard_id,
        count(*) as flagged_submissions
    from high_scores
    where flagged_for_cheating
    group by 1, 2

),

final as (

    select
        ranked.player_id,
        ranked.title_id,
        ranked.leaderboard_id,
        ranked.best_score,
        ranked.leaderboard_rank,
        ranked.leaderboard_percentile,
        ranked.title_rank,
        coalesce(flagged.flagged_submissions, 0) as flagged_submissions
    from ranked
    left join flagged
        on ranked.player_id = flagged.player_id
        and ranked.leaderboard_id = flagged.leaderboard_id

)

select * from final
