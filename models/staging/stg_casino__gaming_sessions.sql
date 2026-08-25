with source as (

    select *
    from {{ source('casino_gaming_resort', 'gaming_sessions') }}
    where not coalesce(_fivetran_deleted, false)

),

renamed as (

    select
        session_id,
        player_id,
        table_id,
        machine_id,
        employee_id,
        started_at,
        ended_at,
        buy_in_amount,
        cash_out_amount,
        currency_code,
        status as session_status,
        is_active,
        _fivetran_synced as source_synced_at
    from source

)

select * from renamed
