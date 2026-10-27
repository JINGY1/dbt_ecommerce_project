with source as (
    select * from {{ ref('raw_store_orders') }}
),

transformed as (
    select
        order_id,
        customer_id                       as web_customer_id,
        lower(trim(guest_email))          as guest_email,
        order_ts                          as ordered_at,
        amount_usd,
        'store'                           as channel
    from source
)

select * from transformed
