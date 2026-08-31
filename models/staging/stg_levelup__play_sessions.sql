with source as (

    select * from {{ source('level_up_labs', 'play_sessions') }}

),

renamed as (

    select
        session_id,
        player_id,
        title_id,
        platform,
        session_start_at,
        session_end_at,
        duration_seconds,
        device_model,
        app_version,
        {{ clean_country_code('country_code') }} as country_code,
        levels_completed,
        crashed_flag,
        network_type,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

),

deduplicated as (

    select
        *,
        row_number() over (
            partition by session_id
            order by source_synced_at asc, session_start_at asc
        ) as _dedupe_rank
    from renamed

)

select * exclude (_dedupe_rank)
from deduplicated
where _dedupe_rank = 1
