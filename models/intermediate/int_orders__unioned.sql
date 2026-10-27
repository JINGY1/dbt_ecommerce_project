with order_totals as (
    select
        order_id,
        sum(sale_price_usd)                       as amount_usd
    from {{ ref('stg_thelook__order_items') }}
    group by order_id
),

online as (
    select
        cast(o.order_id as string)                as order_id,
        'online'                                  as channel,
        o.web_customer_id,
        cast(null as string)                      as guest_email,
        o.order_status,
        o.item_count,
        t.amount_usd,
        o.ordered_at,
        greatest(
            o.ordered_at,
            if(o.shipped_at   <= current_timestamp(), o.shipped_at,   o.ordered_at),
            if(o.delivered_at <= current_timestamp(), o.delivered_at, o.ordered_at),
            if(o.returned_at  <= current_timestamp(), o.returned_at,  o.ordered_at)
        )                                         as updated_at
    from {{ ref('stg_thelook__orders') }} o
    left join order_totals t
        on o.order_id = t.order_id
),

store as (
    select
        order_id,
        channel,
        web_customer_id,
        guest_email,
        'complete'                                as order_status,
        cast(null as int64)                       as item_count,
        amount_usd,
        ordered_at,
        ordered_at                                as updated_at
    from {{ ref('stg_pos__store_orders') }}
)

select * from online
union all
select * from store
