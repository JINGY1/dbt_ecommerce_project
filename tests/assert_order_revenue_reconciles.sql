with orders_before_today as (
    select order_id
    from {{ ref('stg_thelook__orders') }}
    where date(ordered_at) < current_date()
),

items as (
    select sum(i.sale_price_usd) as total
    from {{ ref('stg_thelook__order_items') }} i
    join orders_before_today o
        on i.order_id = o.order_id
),

fct as (
    select sum(amount_usd) as total
    from {{ ref('fct_orders') }}
    where channel = 'online'
      and order_date < current_date()
)

select items.total as items_total, fct.total as fct_total
from items cross join fct
where abs(items.total - fct.total) > 0.01
