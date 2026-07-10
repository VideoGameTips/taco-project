# ==============================
# TACO 第4次课 示例3
# TACO vs HOLD 三资产箱线图
# 文件名：boxplot_taco_vs_hold.py
# ==============================

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
DATA_DIR.mkdir(exist_ok=True)

CASES_FILE = PROJECT_ROOT /"data"/ "taco_cases.csv"
OUTPUT_FILE = DATA_DIR / "boxplot_taco_vs_hold.png"

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv：", CASES_FILE)

else:
    df = pd.read_csv(CASES_FILE, parse_dates=["date"])

    # 兼容旧版本 NOT_TACO
    df["result"] = df["result"].replace({"NOT_TACO": "HOLD"})

    assets = ["uso_5d", "gld_5d", "spy_5d"]
    labels = ["USO", "GLD", "SPY"]

    fig, axes = plt.subplots(1, 3, figsize=(14, 5))

    for ax, col, label in zip(axes, assets, labels):
        taco_data = df[df["result"] == "TACO"][col]
        hold_data = df[df["result"] == "HOLD"][col]

        ax.boxplot(
            [taco_data, hold_data]
        )
        ax.set_xticklabels(["TACO", "HOLD"])

        # 0 线非常重要：
        # 高于 0 表示上涨，低于 0 表示下跌
        ax.axhline(
            y=0,
            linestyle="--",
            alpha=0.6
        )

        ax.set_title(label)
        ax.set_ylabel("5-Day Return (%)")

    plt.suptitle("TACO vs HOLD: 5-Day Market Reaction")
    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, dpi=150)
    plt.show()

    print("箱线图已保存到：")
    print(OUTPUT_FILE)