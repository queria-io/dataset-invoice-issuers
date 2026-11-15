{# 最新情報の行だけを残し、1 行を 1 登録番号にする #}

select s.* exclude (is_latest, source_path), f.sha256 as source_sha256
from {{ ref('stg_issuers') }} as s
left join {{ ref('stg_source_file') }} as f on list_contains(f.paths, s.source_path)
where s.is_latest
