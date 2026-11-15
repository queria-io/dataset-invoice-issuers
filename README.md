# dataset-invoice-issuers

Queria のデータセット `invoice_issuers`（適格請求書発行事業者）のリポジトリです。データセットの説明は [docs/index.md](docs/index.md) にあります。

## ビルド

```bash
uv sync
uv run python main.py           # 取得して手元で dbt build（profiles.yml の環境変数が要る）
scripts/build.sh                # 取得・ビルドして Queria に公開する
```

`.github/workflows/sync.yml` が毎月 5 日に作り直します。
