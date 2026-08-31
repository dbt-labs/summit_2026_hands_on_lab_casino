with transactions as (

    select * from {{ ref('fct_transactions') }}

),

skus as (

    select * from {{ ref('dim_skus') }}

),

categorized as (

    select
        transactions.*,
        case
            when transactions.transaction_type = 'premium_purchase' then 'premium_base'
            when skus.sku_category is not null then skus.sku_category
            else 'unattributed_reversal'
        end as purchase_category,
        date_trunc('month', transactions.transaction_at) as month
    from transactions
    left join skus
        on transactions.sku_id = skus.sku_id

),

title_month_totals as (

    select
        title_id,
        month,
        count(distinct case when is_live_service_revenue or transaction_type = 'premium_purchase'
            then player_id end) as title_month_paying_players
    from categorized
    group by 1, 2

),

final as (

    select
        categorized.title_id,
        categorized.purchase_category,
        categorized.month,
        sum(categorized.gross_amount_usd) as gross_revenue_usd,
        sum(categorized.net_amount_usd) as net_revenue_usd,
        sum(categorized.studio_net_revenue_usd) as studio_net_revenue_usd,
        sum(case when categorized.transaction_type in ('refund', 'chargeback')
            then categorized.gross_amount_usd else 0 end) as refund_gross_usd,
        count(distinct categorized.player_id) as category_players,
        title_month_totals.title_month_paying_players,
        count(distinct categorized.player_id)::float
            / nullif(title_month_totals.title_month_paying_players, 0) as attach_rate,
        avg(case when categorized.is_first_purchase then 1.0 else 0.0 end) as first_purchase_conversion_rate,
        sum(case when categorized.transaction_type in ('refund', 'chargeback') then categorized.gross_amount_usd else 0 end)
            / nullif(sum(categorized.gross_amount_usd), 0) as refund_rate
    from categorized
    left join title_month_totals
        on categorized.title_id = title_month_totals.title_id
        and categorized.month = title_month_totals.month
    group by 1, 2, 3, title_month_totals.title_month_paying_players

)

select * from final
order by title_id, month, purchase_category
