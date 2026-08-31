with platforms as (

    select * from {{ ref('stg_levelup__platforms') }}

)

select
    platform_id,
    platform_name,
    platform_family,
    storefront_fee_rate
from platforms
