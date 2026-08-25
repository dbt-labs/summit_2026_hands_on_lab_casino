with source as (

    select *
    from {{ source('casino_gaming_resort', 'wagers') }}
    where not coalesce(_fivetran_deleted, false)

),

renamed as (

    select
        wager_id,
        session_id,
        wager_at,
        bet_type,
        outcome,
        wager_amount,
        payout_amount,
        currency_code,
        status as wager_status,
        is_active,
        _fivetran_synced as source_synced_at
    from source

)

select * from renamed
