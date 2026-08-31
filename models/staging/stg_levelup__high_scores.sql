with source as (

    select * from {{ source('level_up_labs', 'high_scores') }}

),

renamed as (

    select
        score_id,
        player_id,
        title_id,
        leaderboard_id,
        score_value,
        submitted_at,
        is_verified,
        flagged_for_cheating,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
