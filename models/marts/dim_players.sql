with players as (

    select *
    from {{ ref('stg_casino__players') }}

),

loyalty_accounts as (

    select *
    from {{ ref('stg_casino__loyalty_accounts') }}

),

ranked_loyalty_accounts as (

    select
        *,
        row_number() over (
            partition by player_id
            order by enrolled_at desc, loyalty_id desc
        ) as account_recency_rank
    from loyalty_accounts

),

loyalty_rollup as (

    select
        player_id,
        count(*) as loyalty_account_count,
        sum(points_balance) as total_points_balance,
        sum(lifetime_points) as total_lifetime_points,
        max(source_synced_at) as loyalty_source_synced_at
    from loyalty_accounts
    group by player_id

),

latest_loyalty_account as (

    select
        player_id,
        loyalty_id as latest_loyalty_id,
        card_number as latest_loyalty_card_number,
        loyalty_tier as latest_loyalty_tier,
        enrolled_at as latest_loyalty_enrolled_at,
        tier_expires_at as latest_loyalty_tier_expires_at,
        loyalty_status as latest_loyalty_status
    from ranked_loyalty_accounts
    where account_recency_rank = 1

),

final as (

    select
        players.player_id,
        players.first_name,
        players.last_name,
        players.email,
        players.phone,
        players.date_of_birth,
        players.home_city,
        players.home_state,
        players.home_country,
        players.signup_at,
        players.preferred_game_type,
        players.vip_tier,
        players.player_status,
        players.is_active,
        coalesce(loyalty_rollup.loyalty_account_count, 0) as loyalty_account_count,
        coalesce(loyalty_rollup.total_points_balance, 0) as total_points_balance,
        coalesce(loyalty_rollup.total_lifetime_points, 0) as total_lifetime_points,
        latest_loyalty_account.latest_loyalty_id,
        latest_loyalty_account.latest_loyalty_card_number,
        latest_loyalty_account.latest_loyalty_tier,
        latest_loyalty_account.latest_loyalty_enrolled_at,
        latest_loyalty_account.latest_loyalty_tier_expires_at,
        latest_loyalty_account.latest_loyalty_status,
        players.source_synced_at as player_source_synced_at,
        loyalty_rollup.loyalty_source_synced_at
    from players
    left join loyalty_rollup
        on players.player_id = loyalty_rollup.player_id
    left join latest_loyalty_account
        on players.player_id = latest_loyalty_account.player_id

)

select * from final
