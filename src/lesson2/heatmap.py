import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

CASES_FILE = PROJECT_ROOT / "data"/ "taco_cases.csv"

OUTPUT_FILE = PROJECT_ROOT / "data" / "correlation_heatmap.png"
#where does it metion color
#line 34: image = ax.imshow(corr_df, cmap="coolwarm", vmin=-1, vmax=1)

if not CASES_FILE.exists():
    print("没有找到 taco_cases.csv。")
    print("这部分可以等第4课案例库整理完成后再运行。")

else:
    df = pd.read_csv(CASES_FILE)

    # 基础列：强硬度 + 三个资产 5 日涨跌幅
    columns = ["hardness", "uso_5d", "gld_5d", "spy_5d"]

    # 如果案例库里有 qqq_5d，也把它加入分析
    if "qqq_5d" in df.columns:
        columns.append("qqq_5d")

    # 检查缺失列
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

        cmap = LinearSegmentedColormap.from_list(
            "cyan_magenta",
            ["#00B8D9", "white", "#D81B60"],
            N=256,
        )

        fig, ax = plt.subplots(figsize=(7, 6))
        image = ax.imshow(
            corr_df,
            cmap=cmap,
            vmin=-1,
            vmax=1,
            interpolation="bilinear",
        )
        ax.set_xticks(range(len(corr_df.columns)))
        ax.set_yticks(range(len(corr_df.index)))
        ax.set_xticklabels(corr_df.columns, rotation=45, ha="right")# len() takes no keyword arguments
        ax.set_yticklabels(corr_df.index)
        for i in range (len(corr_df.index)):
            for j in range(len(corr_df.columns)):
                value = corr_df.iloc[i, j]
                ax.text(j, i, f"{value:.2f}", ha="center", va="center", color="black")
        fig.colorbar(image, ax=ax)
        ax.set_title("Correlation Heatmap", fontsize=16)
        plt.tight_layout()
        plt.savefig(OUTPUT_FILE, dpi=300)
        plt.close(fig)
