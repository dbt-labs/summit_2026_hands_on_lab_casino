with source as (

    select * from {{ source('level_up_labs', 'title_platforms') }}

),

renamed as (

    select
        title_platform_id,
        title_id,
        platform_id,
        platform_launch_date,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
