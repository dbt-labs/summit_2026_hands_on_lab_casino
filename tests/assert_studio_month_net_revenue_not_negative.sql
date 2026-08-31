-- Studio-wide net revenue should never go negative in a month, even with refunds/chargebacks netted in.
select
    month,
    studio_net_revenue_usd
from {{ ref('mart_studio_kpis') }}
where studio_net_revenue_usd < 0
