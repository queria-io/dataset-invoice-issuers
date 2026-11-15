{# 最新情報の行だけを残し、1 行を 1 登録番号にする #}

select * exclude (is_latest)
from {{ ref('stg_issuers') }}
where is_latest
