with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="'" ~ var('window_start_date') ~ "'::date",
        end_date="dateadd(day, 1, '" ~ var('date_spine_end_date') ~ "'::date)"
    ) }}

),

final as (

    select
        date_day::date as date_day,
        date_part('year', date_day) as year,
        date_part('month', date_day) as month,
        date_part('day', date_day) as day_of_month,
        date_part('dayofweek', date_day) as day_of_week,
        date_trunc('week', date_day)::date as week_start_date,
        date_trunc('month', date_day)::date as month_start_date,
        date_day between '{{ var("window_start_date") }}'::date and '{{ var("date_spine_end_date") }}'::date
            as is_within_history_window
    from date_spine

)

select * from final
