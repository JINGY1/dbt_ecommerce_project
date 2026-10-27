-- Identity resolution must never lose a thelook account.
select
    (select count(*) from {{ ref('stg_thelook__users') }})                                   as web_accounts,
    (select count(*) from {{ ref('dim_customer_profile') }} where web_customer_id is not null) as web_people
from (select 1)
where (select count(*) from {{ ref('stg_thelook__users') }})
   != (select count(*) from {{ ref('dim_customer_profile') }} where web_customer_id is not null)
