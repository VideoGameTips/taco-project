# ==============================
# TACO 第4次课 示例5
# 领域分层分析
# 文件名：domain_analysis.py
# ==============================

import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
DATA_DIR.mkdir(exist_ok=True)

CASES_FILE = PROJECT_ROOT / "data"/ "taco_cases.csv"
OUTPUT_FILE = DATA_DIR / "domain_uso_bar.png"
SUMMARY_FILE = DATA_DIR / "domain_summary.csv"

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv：", CASES_FILE)

else:
    df = pd.read_csv(CASES_FILE, parse_dates=["date"])
    df["result"] = df["result"].replace({"NOT_TACO": "HOLD"})

    # 1. 每个领域下 TACO / HOLD 数量
    stats = df.groupby(["domain", "result"]).size().unstack(fill_value=0)
    print(stats)

    # 如果某些列不存在，补 0，避免 KeyError
    if "TACO" not in stats.columns:
        stats["TACO"] = 0

    if "HOLD" not in stats.columns:
        stats["HOLD"] = 0

    # 2. 计算 TACO 率
    stats["total"] = stats["TACO"] + stats["HOLD"]
    stats["taco_rate"] = (stats["TACO"] / stats["total"] * 100).round(1)

    # 3. 每个领域平均强硬度
    hardness_avg = df.groupby("domain")["hardness"].mean().round(2)
    stats["avg_hardness"] = hardness_avg

    # 4. 每个领域平均市场反应
    market_avg = df.groupby("domain")[["uso_5d", "gld_5d", "spy_5d"]].mean().round(2)

    summary = stats.join(market_avg)

    print("领域分层分析结果：")
    print(summary)

    # 保存汇总表
    summary.to_csv(SUMMARY_FILE, encoding="utf-8-sig")
    print("\n领域分析汇总表已保存到：")
    print(SUMMARY_FILE)

    # 5. 画 USO 平均反应柱状图
    uso_by_domain = df.groupby("domain")["uso_5d"].mean().sort_values(ascending=False)

    fig, ax = plt.subplots(figsize=(8, 5))

    uso_by_domain.plot(kind="bar", ax=ax)

    ax.axhline(y=0, linestyle="--", alpha=0.6)

    ax.set_title("Average USO 5-Day Return by Domain")
    ax.set_xlabel("Domain")
    ax.set_ylabel("Average USO 5-Day Return (%)")

    plt.tight_layout()
    plt.savefig(OUTPUT_FILE, dpi=150)
    plt.show()

    print("\n领域 USO 柱状图已保存到：")
    print(OUTPUT_FILE)