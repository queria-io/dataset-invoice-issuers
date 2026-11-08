# 適格請求書発行事業者

国税庁の[適格請求書発行事業者公表サイト](https://www.invoice-kohyo.nta.go.jp/)が毎月公開する全件データのうち、法人と人格のない社団等を SQL で検索できるテーブルにしたデータセットです。登録番号・名称・所在地と、登録・失効・取消の年月日を収録し、毎月更新します。

## 出典と利用条件

[全件データのダウンロード](https://www.invoice-kohyo.nta.go.jp/download/zenken)（国税庁）から CSV 形式の全件データを取得して加工しています。列の定義は国税庁の[リソース定義書](https://www.invoice-kohyo.nta.go.jp/files/k-resource-dl.pdf)に従います。

- 公表サイトのコンテンツは[公共データ利用規約（第1.0版）](https://www.digital.go.jp/resources/open_data/public_data_license_v1.0)に準拠した利用条件で提供されています（[利用規約](https://www.invoice-kohyo.nta.go.jp/terms-of-use.html)）
- 使うときは「国税庁適格請求書発行事業者公表サイト（国税庁）（https://www.invoice-kohyo.nta.go.jp/download/zenken）を加工して作成」のように、出典と加工したことを明記してください
- 取引先の登録が有効かどうかの最終確認は、公表サイトで行ってください

## テーブル

| テーブル | 内容 |
| --- | --- |
| `main.issuers` | 1 行が 1 登録番号。法人と人格のない社団等。失効・取消になった事業者も含みます |

- 法人の登録番号は「T + 法人番号」です。`corporate_number` で法人番号のデータセットと結合できます
- 人格のない社団等は法人番号を持たないこともあり、登録番号から区別できないので `corporate_number` は NULL です
- 個人事業者は含みません

## 使い方

法人番号から登録番号と登録の状態を引く:

```sql
SELECT registration_number, name, is_registered, registration_date, expire_date
FROM invoice_issuers.main.issuers
WHERE corporate_number = '7000012050002';
```

都道府県別の登録中の法人数:

```sql
SELECT prefecture_code, count(*) AS issuers
FROM invoice_issuers.main.issuers
WHERE entity_type = 'corporation' AND is_registered
GROUP BY prefecture_code
ORDER BY prefecture_code;
```

## 収録範囲の注意

- 前月末時点のデータです。`file_date` が基準日で、`is_registered` はその日の状態です。基準日より後の登録日・失効日も入っているので、ほかの日の状態は日付の列から判定してください
- 全件データは最新の情報だけを持ちます。名称や所在地を変更した事業者は、変更前の値を持ちません
- 人格のない社団等の所在地は、公表を申し出た事業者だけに入ります

## ビルド

```bash
uv sync
uv run python main.py           # 取得して手元で dbt build（profiles.yml の環境変数が要る）
scripts/build.sh                # 取得・ビルドして Queria に公開する
```

`.github/workflows/sync.yml` が毎月 5 日に作り直します。
