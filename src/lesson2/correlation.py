# ==============================
# TACO 第3次课 进阶示例
# 计算强硬度和资产涨跌幅相关矩阵
# 文件名：correlation.py
# ==============================

import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

# taco_cases.csv 通常放在项目根目录
CASES_FILE = PROJECT_ROOT / "taco_cases.csv"

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv。")
    print("这部分可以等第4课案例库整理完成后再运行。")

else:
    df = pd.read_csv(CASES_FILE)

    # 检查需要的列
    columns = ["hardness", "uso_5d", "gld_5d", "spy_5d"]

    missing_columns = []
    for col in columns:
        if col not in df.columns:
            missing_columns.append(col)

    if len(missing_columns) > 0:
        print("缺少以下列，无法计算相关性：")
        print(missing_columns)

    else:
        corr_df = df[columns].corr()

        print("相关矩阵：")
        print(corr_df)