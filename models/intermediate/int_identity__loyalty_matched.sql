-- One row per loyalty email, with a match decision against thelook.
-- Rule: merge only when the email belongs to exactly one thelook account.

with loyalty as (
    -- Lindsey Hill's two memberships collapse into one row here
    select
        email,
        string_agg(loyalty_member_id, ',' order by loyalty_member_id)           as loyalty_member_ids,
        count(*)                                                                as membership_count,
        min(joined_at)                                                          as loyalty_joined_at,
        array_agg(country_code ignore nulls order by joined_at desc limit 1)[safe_offset(0)] as loyalty_country_code,
        array_agg(phone        ignore nulls order by joined_at desc limit 1)[safe_offset(0)] as phone
    from {{ ref('stg_loyalty__members') }}
    group by email
),

web_accounts as (
    select
        email,
        count(*)                as web_account_count,
        min(web_customer_id)    as web_customer_id
    from {{ ref('stg_thelook__users') }}
    group by email
)

select
    l.*,
    coalesce(w.web_account_count, 0)                                as web_account_count,
    if(w.web_account_count = 1, w.web_customer_id, null)            as matched_web_customer_id,
    case
        when w.web_account_count is null then 'loyalty_only'
        when w.web_account_count = 1     then 'matched'
        else                                  'ambiguous'
    end                                                             as match_status
from loyalty l
left join web_accounts w
    on l.email = w.email
