with source as (

    select * from {{ source('level_up_labs', 'skus') }}

),

renamed as (

    select
        sku_id,
        title_id,
        trim(sku_name) as sku_name,
        sku_category,
        price_usd,
        is_active,
        first_available_date,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
