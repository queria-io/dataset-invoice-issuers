{# 全件データの行を型付けする。最新履歴が 0 の行は、登録番号と日付のほかが空 #}

with typed as (
    select
        registration_number,
        latest = '1' as is_latest,
        -- ファイル名の先頭が h なら法人、j なら人格のない社団等
        starts_with(parse_filename(filename), 'h_') as is_corporation,
        cast(strptime(regexp_extract(parse_filename(filename), '_all_(\d{8})', 1), '%Y%m%d') as date) as file_date,
        process,
        country,
        cast(nullif(registration_date, '') as date) as registration_date,
        cast(nullif(update_date, '') as date) as update_date,
        cast(nullif(disposal_date, '') as date) as disposal_date,
        cast(nullif(expire_date, '') as date) as expire_date,
        name,
        nullif(kana, '') as name_kana,
        -- 法人は本店の所在地 (項番 18〜20)、人格のない社団等は公表を申し出た所在地 (項番 21〜23)
        coalesce(nullif(address, ''), nullif(address_request, '')) as address,
        coalesce(nullif(address_prefecture_code, ''), nullif(address_request_prefecture_code, '')) as prefecture_code,
        coalesce(nullif(address_city_code, ''), nullif(address_request_city_code, '')) as city_code,
        nullif(address_inside, '') as domestic_office_address,
        nullif(address_inside_prefecture_code, '') || nullif(address_inside_city_code, '') as domestic_office_city_code
    from {{ ref('raw_issuers') }}
)

select
    registration_number,
    is_latest,
    -- 法人の登録番号は T + 法人番号。人格のない社団等は法人番号を持たないこともあり、区別できないので入れない
    case when is_corporation then substr(registration_number, 2) end as corporate_number,
    case when is_corporation then 'corporation' else 'association' end as entity_type,
    country,
    process,
    registration_date,
    update_date,
    disposal_date,
    expire_date,
    registration_date <= file_date
        and (disposal_date is null or disposal_date > file_date)
        and (expire_date is null or expire_date > file_date) as is_registered,
    name,
    name_kana,
    address,
    prefecture_code,
    city_code,
    {{ local_government_code('prefecture_code || city_code') }} as lg_code,
    domestic_office_address,
    {{ local_government_code('domestic_office_city_code') }} as domestic_office_lg_code,
    file_date
from typed
