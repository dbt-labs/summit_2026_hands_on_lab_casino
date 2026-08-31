-- A title's total refunded/charged-back gross should never exceed its total gross sold.
with by_title as (

    select
        title_id,
        sum(case when transaction_type in ('premium_purchase', 'iap', 'season_pass', 'dlc')
            then gross_amount_usd else 0 end) as total_gross_usd,
        sum(case when transaction_type in ('refund', 'chargeback') then gross_amount_usd else 0 end) as total_refund_gross_usd
    from {{ ref('fct_transactions') }}
    group by 1

)

select *
from by_title
where total_refund_gross_usd > total_gross_usd
