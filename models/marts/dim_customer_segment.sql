with order_stats as (
    select
        person_key,
        count(*)                as order_count,
        sum(amount_usd)         as lifetime_value_usd,
        max(ordered_at)         as last_ordered_at
    from {{ ref('fct_orders') }}
    where is_revenue
      and person_key is not null
    group by person_key
)

select
    p.person_key,
    coalesce(s.order_count, 0)                                  as order_count,
    coalesce(s.lifetime_value_usd, 0)                           as lifetime_value_usd,
    s.last_ordered_at,
    date_diff(current_date(), date(s.last_ordered_at), day)     as days_since_last_order,
    -- rules apply in order; lapsed comes before high_value on purpose 
    case
        when s.person_key is null
            then 'no_purchase'
        when s.last_ordered_at < timestamp_sub(current_timestamp(), interval {{ var('segment_lapsed_days') }} day)
            then 'lapsed'
        when s.lifetime_value_usd >= {{ var('segment_high_value_usd') }}
            then 'high_value'
        when s.order_count >= 2
            then 'repeat'
        else 'single_purchase'
    end                                                         as segment
from {{ ref('dim_customer_profile') }} p
left join order_stats s
    on p.person_key = s.person_key
