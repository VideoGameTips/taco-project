# ==============================
# TACO 第4次课 示例2
# 检查案例库格式是否标准
# 文件名：check_cases.py
# ==============================

import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
CASES_FILE = PROJECT_ROOT /"data"/ "taco_cases.csv"

required_columns = [
    "date",
    "hardness",
    "domain",
    "result",
    "uso_5d",
    "gld_5d",
    "spy_5d"
]

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv：", CASES_FILE)

else:
    df = pd.read_csv(CASES_FILE, parse_dates=["date"])

    # 兼容旧版本 NOT_TACO
    df["result"] = df["result"].replace({"NOT_TACO": "HOLD"})

    print("开始检查案例库格式...")
    print("=" * 50)

    # 1. 检查列名
    print("\n===== 1. 列名检查 =====")
    missing_columns = []

    for col in required_columns:
        if col not in df.columns:
            missing_columns.append(col)

    # summary 字段可能是 summary，也可能是 summary_zh / summary_en
    has_summary = (
        "summary" in df.columns
        or "summary_zh" in df.columns
        or "summary_en" in df.columns
    )

    if not has_summary:
        missing_columns.append("summary 或 summary_zh / summary_en")

    if len(missing_columns) == 0:
        print("列名完整。")
    else:
        print("缺少以下列：")
        print(missing_columns)

    # 2. 检查空值
    print("\n===== 2. 缺失值检查 =====")
    print(df.isna().sum())

    # 3. 检查 result
    print("\n===== 3. result 检查 =====")
    valid_results = ["TACO", "HOLD"]

    invalid_result_rows = df[~df["result"].isin(valid_results)]

    if len(invalid_result_rows) == 0:
        print("result 列格式正常。")
    else:
        print("result 列存在不规范内容：")
        print(invalid_result_rows[["date", "result"]])

    # 4. 检查 hardness
    print("\n===== 4. hardness 检查 =====")
    invalid_hardness_rows = df[
        (df["hardness"] < 1) | (df["hardness"] > 10)
    ]

    if len(invalid_hardness_rows) == 0:
        print("hardness 范围正常。")
    else:
        print("hardness 存在超出范围的数值：")
        print(invalid_hardness_rows[["date", "hardness"]])

    print("\n检查完成。")