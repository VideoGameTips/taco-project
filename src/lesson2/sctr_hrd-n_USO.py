# ==============================
# TACO 第4次课 示例4
# 强硬度 vs USO 涨跌幅散点图
# 文件名：scatter_hardness_uso.py
# ==============================

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
DATA_DIR.mkdir(exist_ok=True)

CASES_FILE = PROJECT_ROOT /"data"/ "taco_cases.csv"
OUTPUT_FILE = DATA_DIR / "scatter_hardness_uso.png"

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv：", CASES_FILE)

else:
    df = pd.read_csv(CASES_FILE, parse_dates=["date"])
    df["result"] = df["result"].replace({"NOT_TACO": "HOLD"})

    fig, ax = plt.subplots(figsize=(8, 5))

    # 分别画 TACO 和 HOLD，方便观察两组差异
    for result_type, marker in [("TACO", "o"), ("HOLD", "^")]:
        mask = df["result"] == result_type

        ax.scatter(
            df[mask]["hardness"],
            df[mask]["uso_5d"],
            marker=marker,
            label=result_type,
            s=80,
            alpha=0.8
        )

    # 添加趋势线
    # np.polyfit(x, y, 1) 表示拟合一条一次直线
    z = np.polyfit(df["hardness"], df["uso_5d"], 1)
    p = np.poly1d(z)

    x = np.linspace(1, 10, 100)
    ax.plot(
        x,
        p(x),
        linestyle="--",
        alpha=0.7,
        label="Trend Line"
    )

    ax.axhline(y=0, linestyle="--", alpha=0.5)

    ax.set_title("Hardness vs USO 5-Day Return")
    ax.set_xlabel("Hardness Score")
    ax.set_ylabel("USO 5-Day Return (%)")
    ax.legend()

    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, dpi=150)
    plt.show()

    print("散点图已保存到：")
    print(OUTPUT_FILE)

    print("\n趋势线公式大致为：")
    print(f"USO_5D = {z[0]:.2f} * hardness + {z[1]:.2f}")