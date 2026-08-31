with source as (

    select * from {{ source('level_up_labs', 'platforms') }}

),

renamed as (

    select
        platform_id,
        platform_name,
        platform_family,
        storefront_fee_rate,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
