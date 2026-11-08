"""適格請求書発行事業者（インボイス登録事業者）データパイプライン。

1. invoice: 公表サイトから法人と人格のない社団等の全件データを取り出す
2. dbt: dbt ビルド
"""

import logging

from dbt.cli.main import dbtRunner

from pipelines.invoice import download_invoice

# dbt を読み込むとルートロガーが先に設定されるので、force で上書きする
logging.basicConfig(level=logging.INFO, format="%(message)s", force=True)
logger = logging.getLogger("pipelines")


def dbt_build():
    dbt = dbtRunner()
    for command in (["deps"], ["build"], ["docs", "generate"]):
        if not dbt.invoke(command).success:
            raise SystemExit(f"dbt {' '.join(command)} failed")


def main():
    logger.info("1/2: invoice (全件データ)")
    download_invoice()

    logger.info("2/2: dbt build")
    dbt_build()


if __name__ == "__main__":
    main()
