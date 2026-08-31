with source as (

    select * from {{ source('level_up_labs', 'titles') }}

),

renamed as (

    select
        title_id,
        trim(title_name) as title_name,
        genre,
        monetization_model,
        list_price_usd,
        launch_date,
        is_live_service,
        sunset_date,
        dev_team,
        engine,
        esrb_rating,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
