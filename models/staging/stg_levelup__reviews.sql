with source as (

    select * from {{ source('level_up_labs', 'reviews') }}

),

renamed as (

    select
        review_id,
        player_id,
        title_id,
        platform,
        rating,
        review_text_length,
        reviewed_at,
        is_recommended,
        playtime_at_review_hours,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
