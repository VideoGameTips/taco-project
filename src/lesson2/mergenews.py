# ==============================
# TACO 第2次课 示例7
# 合并新闻数据和市场数据
# 文件名：merge_news_market.py
# ==============================

import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"

NEWS_FILE = DATA_DIR / "clean_news.csv"
MARKET_FILE = DATA_DIR / "market_data_2018_2025.csv"

OUTPUT_FILE = DATA_DIR / "merged_news_market.csv"

if not NEWS_FILE.exists():
    print("没有找到 clean_news.csv。")
    print("请先运行 clean_data.py。")

elif not MARKET_FILE.exists():
    print("没有找到 market_data_2018_2025.csv。")
    print("请把市场数据文件放到 data 文件夹。")

else:
    # 读取新闻数据
    news_df = pd.read_csv(NEWS_FILE)

    # 读取市场数据
    market_df = pd.read_csv(MARKET_FILE)

    # 统一日期格式
    news_df["date"] = pd.to_datetime(news_df["date"]).dt.date
    market_df["date"] = pd.to_datetime(market_df["date"]).dt.date

    print("新闻数据行数：", len(news_df))
    print("市场数据行数：", len(market_df))

    # 按 date 合并
    # how="inner" 表示只保留两边都有的日期
    merged_df = pd.merge(
        news_df,
        market_df,
        on="date",
        how="inner"
    )

    print("\n合并后数据形状：")
    print(merged_df.shape)

    print("\n合并后数据预览：")
    print(merged_df.head())

    print("\n空值检查：")
    print(merged_df.isnull().sum())

    # 保存合并后的数据
    merged_df.to_csv(OUTPUT_FILE, index=False, encoding="utf-8-sig")

    print("\n合并后的数据已保存到：")
    print(OUTPUT_FILE)