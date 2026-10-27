with source as (
    select * from {{ source('thelook', 'order_items') }}
),

renamed as (
    select
        id                                        as order_item_id,
        order_id,
        user_id                                   as web_customer_id,
        product_id,
        lower(status)                             as item_status,
        round(cast(sale_price as numeric), 2)     as sale_price_usd,
        created_at                                as ordered_at
    from source
)

select * from renamed
