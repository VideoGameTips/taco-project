# ==============================
# TACO 第4次课 示例6
# 格式化为 RAG 知识库数据
# 文件名：format_rag.py
# ==============================

import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "data"
DATA_DIR.mkdir(exist_ok=True)

CASES_FILE = PROJECT_ROOT / "taco_cases.csv"
OUTPUT_FILE = DATA_DIR / "rag_cases.csv"

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv：", CASES_FILE)

else:
    df = pd.read_csv(CASES_FILE, parse_dates=["date"])
    df["result"] = df["result"].replace({"NOT_TACO": "HOLD"})

    def get_summary(row):
        """
        获取案例摘要。
        优先使用中文摘要 summary_zh。
        如果没有，再尝试 summary。
        如果还没有，再尝试 summary_en。
        """

        if "summary_zh" in row.index and pd.notna(row["summary_zh"]):
            return row["summary_zh"]

        if "summary" in row.index and pd.notna(row["summary"]):
            return row["summary"]

        if "summary_en" in row.index and pd.notna(row["summary_en"]):
            return row["summary_en"]

        return "无摘要"

    def format_for_rag(row):
        """
        把一行结构化案例转换成自然语言文本。
        这个文本会成为 Dify RAG 知识库的输入。
        """

        if row["result"] == "TACO":
            result_text = "最终 TACO（软化、推迟或让步）"
        else:
            result_text = "HOLD（坚持原立场，没有明显软化）"

        summary = get_summary(row)

        return f"""日期：{row['date'].date()}
事件：{summary}
强硬度：{row['hardness']}/10
领域：{row['domain']}
结果：{result_text}
市场反应（事件后5个交易日）：
- 石油 USO：{row['uso_5d']:+.1f}%
- 黄金 GLD：{row['gld_5d']:+.1f}%
- 美股 SPY：{row['spy_5d']:+.1f}%
"""

    # axis=1 表示按行处理
    df["rag_text"] = df.apply(format_for_rag, axis=1)

    # 保存 date 和 rag_text 两列
    df[["date", "rag_text"]].to_csv(
        OUTPUT_FILE,
        index=False,
        encoding="utf-8-sig"
    )

    print("RAG 案例文件已保存到：")
    print(OUTPUT_FILE)

    print("\n第 1 条案例预览：")
    print(df["rag_text"].iloc[0])

    print("\n最后 1 条案例预览：")
    print(df["rag_text"].iloc[-1])