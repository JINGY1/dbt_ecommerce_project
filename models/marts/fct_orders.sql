-- Plain table while on the BigQuery sandbox: MERGE is unavailable there, and
-- partitions older than 60 days are deleted. Restore incremental + partition_by
-- once billing is enabled.
{{ config(
    materialized = 'table',
    cluster_by = ['channel', 'order_status']
) }}

with orders as (
    select * from {{ ref('int_orders__unioned') }}
),

people_by_web_id as (
    select web_customer_id, person_key
    from {{ ref('dim_customer_profile') }}
    where web_customer_id is not null
),

-- guest emails resolve only when exactly one person has that email
people_by_email as (
    select email, any_value(person_key) as person_key
    from {{ ref('dim_customer_profile') }}
    group by email
    having count(*) = 1
)

select
    o.order_id,
    coalesce(pw.person_key, pe.person_key)                  as person_key,
    o.channel,
    o.web_customer_id,
    o.guest_email,
    o.order_status,
    o.order_status in ('complete', 'shipped', 'processing') as is_revenue,
    o.item_count,
    o.amount_usd,
    o.ordered_at,
    date(o.ordered_at)                                      as order_date,
    o.updated_at
from orders o
left join people_by_web_id pw
    on o.web_customer_id = pw.web_customer_id
left join people_by_email pe
    on o.guest_email = pe.email
