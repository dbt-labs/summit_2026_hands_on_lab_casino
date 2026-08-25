with source as (

    select *
    from {{ source('casino_gaming_resort', 'loyalty_accounts') }}
    where not coalesce(_fivetran_deleted, false)

),

renamed as (

    select
        loyalty_id,
        player_id,
        card_number,
        tier as loyalty_tier,
        points_balance,
        lifetime_points,
        enrolled_at,
        tier_expires_at,
        status as loyalty_status,
        is_active,
        _fivetran_synced as source_synced_at
    from source

)

select * from renamed
