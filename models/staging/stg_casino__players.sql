with source as (

    select *
    from {{ source('casino_gaming_resort', 'players') }}
    where not coalesce(_fivetran_deleted, false)

),

renamed as (

    select
        player_id,
        trim(first_name) as first_name,
        trim(last_name) as last_name,
        lower(trim(email)) as email,
        phone,
        cast(date_of_birth as date) as date_of_birth,
        home_city,
        home_state,
        home_country,
        signup_at,
        preferred_game_type,
        vip_tier,
        status as player_status,
        is_active,
        _fivetran_synced as source_synced_at
    from source

)

select * from renamed
