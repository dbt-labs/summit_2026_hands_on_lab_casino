with source as (

    select * from {{ source('level_up_labs', 'transactions') }}

),

renamed as (

    select
        transaction_id,
        player_id,
        title_id,
        platform,
        transaction_at::timestamp as transaction_at_local,
        {{ to_utc('transaction_at::timestamp') }} as transaction_at,
        transaction_type,
        sku_id,
        gross_amount_usd,
        platform_fee_usd,
        currency_code,
        local_amount,
        payment_method,
        is_first_purchase,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
