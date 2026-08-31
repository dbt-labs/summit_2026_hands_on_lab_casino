with source as (

    select * from {{ source('level_up_labs', 'releases') }}

),

renamed as (

    select
        release_id,
        title_id,
        app_version,
        released_at,
        release_type,
        release_notes,
        dev_days_estimated,
        dev_days_actual,
        qa_bug_count,
        is_rollback,
        _fivetran_synced as source_synced_at
    from source
    where coalesce(_fivetran_deleted, false) = false

)

select * from renamed
