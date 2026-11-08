{# 全件データ (data/invoice/*.csv) の最新情報の行を型付けする。1 行が 1 登録番号。
   列の並びは国税庁「リソース定義書（ダウンロードファイル、Web-API機能）」の項番 7〜30。
   最新履歴が 0 の行は、登録番号と日付のほかが空なので落とす #}

with source as (
    select *
    from read_csv(
        'data/invoice/*.csv',
        header = false,
        quote = '"',
        filename = true,
        columns = {
            'sequence_number': 'VARCHAR',
            'registration_number': 'VARCHAR',
            'process': 'VARCHAR',
            'correct': 'VARCHAR',
            'kind': 'VARCHAR',
            'country': 'VARCHAR',
            'latest': 'VARCHAR',
            'registration_date': 'VARCHAR',
            'update_date': 'VARCHAR',
            'disposal_date': 'VARCHAR',
            'expire_date': 'VARCHAR',
            'address': 'VARCHAR',
            'address_prefecture_code': 'VARCHAR',
            'address_city_code': 'VARCHAR',
            'address_request': 'VARCHAR',
            'address_request_prefecture_code': 'VARCHAR',
            'address_request_city_code': 'VARCHAR',
            'kana': 'VARCHAR',
            'name': 'VARCHAR',
            'address_inside': 'VARCHAR',
            'address_inside_prefecture_code': 'VARCHAR',
            'address_inside_city_code': 'VARCHAR',
            'trade_name': 'VARCHAR',
            'popular_name_previous_name': 'VARCHAR'
        }
    )
    where latest = '1'
),

typed as (
    select
        registration_number,
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
    from source
)

select
    registration_number,
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
