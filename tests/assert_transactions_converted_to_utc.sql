-- transaction_at (UTC) should always be strictly later than transaction_at_local
-- (America/New_York is always behind UTC), confirming the to_utc conversion ran.
select
    transaction_id,
    transaction_at,
    transaction_at_local
from {{ ref('stg_levelup__transactions') }}
where transaction_at <= transaction_at_local
