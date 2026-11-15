{# 全件データ (data/invoice/*.csv) を取得したままの形で読む。ヘッダーの無い CSV なので、
   列名は国税庁「リソース定義書（ダウンロードファイル、Web-API機能）」の項番 7〜30 に合わせて付ける #}

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
