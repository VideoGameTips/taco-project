# ==============================
# TACO 第2次课 示例6
# 新闻清洗函数
# 文件名：clean_data.py
# ==============================

import pandas as pd
import re
from pathlib import Path


def clean_news(df):
    """
    清洗新闻数据。

    参数：
        df: 原始新闻 DataFrame，至少包含 title 和 date 两列

    返回：
        清洗后的 DataFrame
    """

    # 1. 删除标题或日期为空的新闻
    df = df.dropna(subset=["title", "date"])

    # 2. 统一日期格式
    # errors="coerce" 表示无法识别的日期会变成 NaT
    df["date"] = pd.to_datetime(df["date"], errors="coerce").dt.date

    # 删除日期转换失败的行
    df = df.dropna(subset=["date"])

    # 3. 去除 HTML 标签
    def strip_html(text):
        return re.sub(r"<[^>]+>", "", str(text))

    df["title"] = df["title"].apply(strip_html)

    if "summary" in df.columns:
        df["summary"] = df["summary"].apply(strip_html)

    # 4. 删除重复新闻
    df = df.drop_duplicates(subset=["date", "title"])

    return df


# ==============================
# 测试清洗函数
# ==============================

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"

raw_news_path = DATA_DIR / "raw_news.csv"
clean_news_path = DATA_DIR / "clean_news.csv"

if not raw_news_path.exists():
    print("没有找到 raw_news.csv。")
    print("请先运行 fetch_news_to_csv.py 抓取新闻。")

else:
    raw_df = pd.read_csv(raw_news_path)

    print("清洗前新闻数量：", len(raw_df))

    clean_df = clean_news(raw_df)

    print("清洗后新闻数量：", len(clean_df))
    print("\n清洗后数据预览：")
    print(clean_df.head())

    clean_df.to_csv(clean_news_path, index=False, encoding="utf-8-sig")

    print("\n清洗后的新闻已保存到：")
    print(clean_news_path)