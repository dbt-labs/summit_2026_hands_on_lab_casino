with players as (

    select * from {{ ref('dim_players') }}

),

sessions as (

    select * from {{ ref('fct_play_sessions') }}

),

cohorts as (

    select
        registration_cohort_month as cohort_month,
        acquisition_channel,
        count(distinct player_id) as cohort_size
    from players
    group by 1, 2

),

week_offsets as (

    select generated_number - 1 as week_offset
    from ({{ dbt_utils.generate_series(9) }})

),

cohort_week_spine as (

    select
        cohorts.cohort_month,
        cohorts.acquisition_channel,
        cohorts.cohort_size,
        week_offsets.week_offset
    from cohorts
    cross join week_offsets

),

retained as (

    select
        players.registration_cohort_month as cohort_month,
        players.acquisition_channel,
        sessions.week_offset_from_registration as week_offset,
        count(distinct sessions.player_id) as retained_players
    from sessions
    inner join players
        on sessions.player_id = players.player_id
    where sessions.week_offset_from_registration between 0 and 8
    group by 1, 2, 3

),

final as (

    select
        cohort_week_spine.cohort_month,
        cohort_week_spine.acquisition_channel,
        cohort_week_spine.week_offset,
        cohort_week_spine.cohort_size,
        coalesce(retained.retained_players, 0) as retained_players,
        coalesce(retained.retained_players, 0)::float / nullif(cohort_week_spine.cohort_size, 0) as retention_rate,
        dateadd('week', cohort_week_spine.week_offset, cohort_week_spine.cohort_month)
            <= '{{ var("analysis_as_of_date") }}'::date as is_observable,
        cohort_week_spine.cohort_size >= {{ var('mart_min_cohort_size') }} as has_sufficient_volume
    from cohort_week_spine
    left join retained
        on cohort_week_spine.cohort_month = retained.cohort_month
        and cohort_week_spine.acquisition_channel = retained.acquisition_channel
        and cohort_week_spine.week_offset = retained.week_offset

)

select * from final
order by cohort_month, acquisition_channel, week_offset
