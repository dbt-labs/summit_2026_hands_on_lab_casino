with skus as (

    select * from {{ ref('stg_levelup__skus') }}

),

titles as (

    select title_id, title_name from {{ ref('stg_levelup__titles') }}

),

final as (

    select
        skus.sku_id,
        skus.title_id,
        titles.title_name,
        skus.sku_name,
        skus.sku_category,
        skus.price_usd,
        skus.is_active,
        skus.first_available_date
    from skus
    left join titles
        on skus.title_id = titles.title_id

)

select * from final
