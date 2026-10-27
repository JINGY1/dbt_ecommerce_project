with web as (
    select
        u.web_customer_id,
        u.email,
        u.first_name,
        u.last_name,
        cc.country_code         as web_country_code,
        u.signed_up_at
    from {{ ref('stg_thelook__users') }} u
    left join {{ ref('country_codes') }} cc
        on u.country_name = cc.country_name
),

loyalty as (
    select * from {{ ref('int_identity__loyalty_matched') }}
),

web_people as (
    select
        to_hex(md5(concat('web:', cast(w.web_customer_id as string))))   as person_key,
        w.web_customer_id,
        l.loyalty_member_ids,
        w.email,
        w.first_name,
        w.last_name,
        coalesce(l.loyalty_country_code, w.web_country_code)            as country_code,
        coalesce(l.loyalty_country_code != w.web_country_code, false)   as has_country_conflict,
        l.phone,
        least(w.signed_up_at, coalesce(l.loyalty_joined_at, w.signed_up_at)) as first_seen_at,
        if(l.email is null, 1, 2)                                       as source_count,
        if(l.email is null, 'web_only', 'matched')                      as match_status
    from web w
    left join loyalty l
        on l.matched_web_customer_id = w.web_customer_id
),

loyalty_people as (
    select
        to_hex(md5(concat('loyalty:', email)))                          as person_key,
        cast(null as int64)                                             as web_customer_id,
        loyalty_member_ids,
        email,
        cast(null as string)                                            as first_name,
        cast(null as string)                                            as last_name,
        loyalty_country_code                                            as country_code,
        false                                                           as has_country_conflict,
        phone,
        loyalty_joined_at                                               as first_seen_at,
        1                                                               as source_count,
        match_status                                                    -- 'loyalty_only' or 'ambiguous'
    from loyalty
    where match_status != 'matched'
)

select * from web_people
union all
select * from loyalty_people
