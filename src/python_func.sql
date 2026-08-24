-- Create Function
create or replace function fake_contact(seed_value string)
returns variant
language python
runtime_version = '3.10'
packages = ('faker')
handler = 'generate_contact'
as
$$
from faker import Faker
import hashlib

def generate_contact(seed_value):
    seed_int = int(hashlib.md5(seed_value.encode()).hexdigest(), 16) % (10**8)
    fake = Faker('pt_BR')
    fake.seed_instance(seed_int)
    return {
        "name": fake.name(),
        "email": fake.email(),
        "phone": fake.phone_number()
    }
$$;

-- Enriching MQL Table
create or replace table mql_enriched as
select
  m.*,
  c.value:name::string as full_name,
  c.value:email::string as email,
  c.value:phone::string as phone,
  true as pewc
from PERSONAL_PROJECT.MARKETING_FUNNEL.OLIST_MARKETING_QUALIFIED_LEADS_DATASET m,
  lateral (select fake_contact(m.mql_id) as value) c;

-- Extending ID for Sellers
create or replace table seller_identity_from_mql as
select
  cd.seller_id,
  me.mql_id,
  me.full_name,
  me.email,
  me.phone,
  me.pewc
from PERSONAL_PROJECT.MARKETING_FUNNEL.OLIST_CLOSED_DEALS_DATASET cd
join mql_enriched me
  on cd.mql_id = me.mql_id;

-- Complementing sellers without MQL ID
create or replace table seller_identity_no_mql as
select
  s.seller_id,
  cast(null as string) as mql_id,
  c.value:name::string as full_name,
  c.value:email::string as email,
  cast(null as string) as phone,
  cast(null as boolean) as pewc
from PERSONAL_PROJECT.ECOMMERCE_DATASET.OLIST_SELLERS_DATASET s,
  lateral (select fake_contact(s.seller_id) as value) c
where s.seller_id not in (select seller_id from PERSONAL_PROJECT.MARKETING_FUNNEL.SELLER_IDENTITY_FROM_MQL);

-- Final table unified
create or replace table seller_identity_full as
select * from PERSONAL_PROJECT.MARKETING_FUNNEL.SELLER_IDENTITY_FROM_MQL
union all
select * from seller_identity_no_mql;