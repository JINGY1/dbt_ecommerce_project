with source as (
    select * from {{ ref('raw_loyalty_members') }}
),

transformed as (
    select
        member_no                         as loyalty_member_id,
        lower(trim(contact_email))        as email,
        nullif(trim(phone), '')           as phone,
        upper(trim(home_country))         as country_code,
        joined_ts                         as joined_at
    from source
)

select * from transformed
