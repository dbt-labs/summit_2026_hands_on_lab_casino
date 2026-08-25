with wagers as (

    select *
    from {{ ref('stg_casino__wagers') }}

),

gaming_sessions as (

    select *
    from {{ ref('stg_casino__gaming_sessions') }}

),

final as (

    select
        wagers.wager_id,
        wagers.session_id,
        gaming_sessions.player_id,
        wagers.wager_at,
        gaming_sessions.started_at as session_started_at,
        gaming_sessions.ended_at as session_ended_at,
        case
            when gaming_sessions.table_id is not null then 'table_game'
            when gaming_sessions.machine_id is not null then 'slot_machine'
        end as session_type,
        gaming_sessions.table_id,
        gaming_sessions.machine_id,
        wagers.bet_type,
        wagers.outcome,
        wagers.wager_amount,
        wagers.payout_amount,
        wagers.payout_amount - wagers.wager_amount as player_net_winnings,
        wagers.wager_amount - wagers.payout_amount as gross_gaming_revenue,
        wagers.currency_code as wager_currency_code,
        gaming_sessions.currency_code as session_currency_code,
        wagers.wager_status,
        wagers.is_active,
        wagers.source_synced_at as wager_source_synced_at,
        gaming_sessions.source_synced_at as session_source_synced_at
    from wagers
    left join gaming_sessions
        on wagers.session_id = gaming_sessions.session_id

)

select * from final
