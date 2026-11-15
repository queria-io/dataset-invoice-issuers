"""国税庁の適格請求書発行事業者公表サイトから全件データ (CSV) を取り出す。

法人 (5 分割) と人格のない社団等の zip を取り、中の CSV を data/invoice/ に置く。
個人の全件データは取らない。

ダウンロードのリンクは毎月変わる管理番号を持つので、全件データのページから
CSV のリンクを読み取る。

出力:
- data/invoice/{h,j}_all_<作成年月日>[_<一連番号>].csv
- data/invoice/source_file.parquet（取得した zip の記録。zip 本体は残さない）

データソース: 国税庁 適格請求書発行事業者公表サイト
https://www.invoice-kohyo.nta.go.jp/download/zenken
"""

import logging
import re
import shutil
import tempfile
import zipfile
from pathlib import Path

from pipelines.source_file import write_source_files
from shared.fetch import fetch, fetch_file

logger = logging.getLogger("pipelines")

SITE = "https://www.invoice-kohyo.nta.go.jp"
USER_AGENT = "dataset-invoice-issuers (+https://github.com/queria-io/dataset-invoice-issuers)"
OUTPUT = Path("data/invoice")
# 人格区分のコード。2 = 法人、3 = 人格のない社団等 (1 = 個人は取らない)
KINDS = {"2": "法人", "3": "人格のない社団等"}
CSV_TYPE = "01"
LINK = re.compile(r"doDownload\('(\d+)','(\d)','(\d{2})'\)")
FILE_NAME = re.compile(r"[hj]_all_\d{8}(?:_\d{3})?\.csv")


def list_files(page: str) -> list[tuple[str, str]]:
    """全件データのページから、取る CSV の (管理番号, 人格区分) を返す。"""
    return [
        (number, kind)
        for number, kind, file_type in LINK.findall(page)
        if file_type == CSV_TYPE and kind in KINDS
    ]


def extract_csv(path: Path, directory: Path) -> list[str]:
    """zip から CSV だけを directory に書き、書いたファイル名を返す。署名 (.asc) は捨てる。"""
    with zipfile.ZipFile(path) as archive:
        names = [name for name in archive.namelist() if FILE_NAME.fullmatch(name)]
        for name in names:
            (directory / name).write_bytes(archive.read(name))
    return names


def download_invoice() -> None:
    page = fetch(f"{SITE}/download/zenken", user_agent=USER_AGENT).decode("utf-8")
    files = list_files(page)
    if not any(kind == "2" for _, kind in files) or not any(kind == "3" for _, kind in files):
        raise SystemExit(f"全件データのリンクが読み取れない: {files}")

    # 書き終わるまで前回の出力を残す。古い月のファイルが混ざらないよう、フォルダごと替える
    partial = OUTPUT.with_name(OUTPUT.name + ".part")
    shutil.rmtree(partial, ignore_errors=True)
    partial.mkdir(parents=True)
    def one(number: str, kind: str, tmp: Path) -> dict:
        url = f"{SITE}/download/zenken/dlfile?dlFilKanriNo={number}&jinkakukbn={kind}&type={CSV_TYPE}"
        archive = tmp / f"{number}_{kind}.zip"
        source = fetch_file(url, archive, user_agent=USER_AGENT, timeout=300)
        names = extract_csv(archive, partial)
        archive.unlink()
        if not names:
            raise SystemExit(f"zip に CSV が無い: {url}")
        logger.info("  %s: %s", KINDS[kind], ", ".join(names))
        return {**source, "page_url": f"{SITE}/download/zenken", "paths": [str(OUTPUT / n) for n in names]}

    with tempfile.TemporaryDirectory() as tmp:
        sources = [one(number, kind, Path(tmp)) for number, kind in files]

    dates = {path.name.split("_")[2][:8] for path in partial.glob("*.csv")}
    if len(dates) != 1:
        raise SystemExit(f"作成年月日の違うファイルが混ざっている: {sorted(dates)}")
    write_source_files(sources, partial / "source_file.parquet")
    shutil.rmtree(OUTPUT, ignore_errors=True)
    partial.rename(OUTPUT)
