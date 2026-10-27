with source as (
    select * from {{ source('thelook', 'orders') }}
),

renamed as (
    select
        order_id,
        user_id                           as web_customer_id,
        lower(status)                     as order_status,
        num_of_item                       as item_count,
        created_at                        as ordered_at,
        shipped_at,
        delivered_at,
        returned_at
    from source
)

select * from renamed
