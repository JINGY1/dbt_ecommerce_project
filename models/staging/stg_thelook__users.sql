with source as (
    select * from {{ source('thelook', 'users') }}
),

renamed as (
    select
        cast(id as int64)                 as web_customer_id,
        lower(trim(email))                as email,
        initcap(trim(first_name))         as first_name,
        initcap(trim(last_name))          as last_name,
        trim(country)                     as country_name,
        traffic_source,
        created_at                        as signed_up_at
    from source
)

select * from renamed
