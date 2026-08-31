with source as (

    select * from {{ source('level_up_labs', 'players') }}

),

renamed as (

    select
        player_id,
        registered_at,
        {{ clean_country_code('country_code') }} as country_code,
        platform_registered_on,
        lower(replace(trim(acquisition_channel), ' ', '_')) as acquisition_channel,
        nullif(trim(acquisition_campaign_id), '') as acquisition_campaign_id,
        birth_year,
        lower(trim(email)) as email,
        marketing_opt_in,
        account_status,
        last_login_at,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
