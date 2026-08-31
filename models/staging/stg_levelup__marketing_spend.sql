with source as (

    select * from {{ source('level_up_labs', 'marketing_spend') }}

),

renamed as (

    select
        spend_id,
        campaign_id,
        title_id,
        channel,
        week_start_date,
        spend_usd,
        impressions,
        clicks,
        installs,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
