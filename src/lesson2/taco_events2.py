# ==============================
# TACO 第3次课 优化版
# 四资产归一化图 + 更清楚的 TACO 事件标注
# 文件名：taco_events_better.py
# ==============================

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.lines import Line2D
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_FILE = PROJECT_ROOT / "data" / "market_data_2018_2025.csv"
OUTPUT_FILE = PROJECT_ROOT / "data" / "taco_events_better.png"

REQUIRED_COLUMNS = [
    "date",
    "USO_Close",
    "GLD_Close",
    "SPY_Close",
    "QQQ_Close"
]

if not DATA_FILE.exists():
    print("没有找到市场数据文件：", DATA_FILE)

else:
    df = pd.read_csv(DATA_FILE, parse_dates=["date"])

    # 检查列名是否完整
    missing_columns = []

    for col in REQUIRED_COLUMNS:
        if col not in df.columns:
            missing_columns.append(col)

    if len(missing_columns) > 0:
        print("市场数据缺少以下列：")
        print(missing_columns)
        print("当前文件中的列名是：")
        print(list(df.columns))

    else:
        df = df.set_index("date")

        price_df = df[[
            "USO_Close",
            "GLD_Close",
            "SPY_Close",
            "QQQ_Close"
        ]].copy()

        price_df.columns = ["USO", "GLD", "SPY", "QQQ"]

        # 删除空值，避免归一化时出错
        price_df = price_df.dropna()

        # 为了图表更清楚，只看 2019 年以后
        price_df = price_df[price_df.index >= "2019-01-01"]

        if price_df.empty:
            print("筛选 2019 年以后数据后为空，请检查市场数据日期范围。")

        else:
            # 归一化：所有资产从 100 出发
            df_norm = price_df / price_df.iloc[0] * 100

            # 事件列表：日期、标签、类型、颜色
            # hard 表示强硬言论，soft 表示软化 / 暂停 / 谈判
            events = [
                {
                    "date": "2019-05-05",
                    "label": "Tariff hike 25%",
                    "event_type": "Hard threat",
                    "color": "red"
                },
                {
                    "date": "2020-01-15",
                    "label": "Phase One Deal",
                    "event_type": "Softening / deal",
                    "color": "green"
                },
                {
                    "date": "2025-04-02",
                    "label": "Liberation Day",
                    "event_type": "Hard threat",
                    "color": "red"
                },
                {
                    "date": "2025-04-09",
                    "label": "90-day Pause",
                    "event_type": "Softening / pause",
                    "color": "green"
                }
            ]

            fig, ax = plt.subplots(figsize=(15, 6))

            # 画四资产归一化走势
            for ticker in df_norm.columns:
                ax.plot(
                    df_norm.index,
                    df_norm[ticker],
                    linewidth=1.8,
                    label=ticker
                )

            # 计算 y 轴范围，让事件文字位置自动适配图表
            y_min = df_norm.min().min()
            y_max = df_norm.max().max()
            y_range = y_max - y_min

            if y_range == 0:
                y_range = 10

            label_y_top = y_max + y_range * 0.18
            label_y_mid = y_max + y_range * 0.05

            ax.set_ylim(
                y_min - y_range * 0.08,
                y_max + y_range * 0.35
            )

            # 标注事件
            for index, event in enumerate(events):
                event_date = pd.Timestamp(event["date"])
                label = event["label"]
                color = event["color"]

                # 如果事件日期不在图表范围内，就跳过
                if event_date < df_norm.index.min() or event_date > df_norm.index.max():
                    print("事件日期不在图表范围内，已跳过：", event_date.date(), label)
                    continue

                # 事件当天竖线
                ax.axvline(
                    x=event_date,
                    linestyle="--",
                    linewidth=1.2,
                    alpha=0.85,
                    color=color
                )

                # 标出事件后 5 天观察窗口
                # 这不是严格交易日窗口，只是视觉上帮助学生理解“事件后几天”
                ax.axvspan(
                    event_date,
                    event_date + pd.Timedelta(days=5),
                    alpha=0.08,
                    color=color
                )

                # 事件文字上下交错，减少重叠
                if index % 2 == 0:
                    text_y = label_y_top
                else:
                    text_y = label_y_mid

                # 事件标签
                ax.annotate(
                    f"{event_date.strftime('%Y-%m-%d')}\n{label}",
                    xy=(event_date, y_max),
                    xytext=(event_date, text_y),
                    ha="center",
                    va="top",
                    fontsize=8,
                    color=color,
                    arrowprops={
                        "arrowstyle": "-",
                        "color": color,
                        "linewidth": 0.8,
                        "alpha": 0.8
                    },
                    bbox={
                        "boxstyle": "round,pad=0.25",
                        "facecolor": "white",
                        "edgecolor": color,
                        "alpha": 0.9
                    }
                )

            # 100 基准线
            ax.axhline(
                y=100,
                linestyle="--",
                linewidth=1,
                alpha=0.7
            )

            # 标题和坐标轴
            ax.set_title(
                "Normalized Asset Prices with TACO Event Markers",
                fontsize=14,
                pad=18
            )

            ax.set_xlabel("Date")
            ax.set_ylabel("Indexed to 100")

            # 网格线，让走势更容易读
            ax.grid(
                True,
                linestyle="--",
                linewidth=0.5,
                alpha=0.35
            )

            # x 轴按年份显示
            ax.xaxis.set_major_locator(mdates.YearLocator(1))
            ax.xaxis.set_major_formatter(mdates.DateFormatter("%Y"))

            # 去掉上边框和右边框，让图更清爽
            ax.spines["top"].set_visible(False)
            ax.spines["right"].set_visible(False)

            # 资产图例
            asset_legend = ax.legend(
                title="Assets",
                loc="upper left",
                ncol=4,
                frameon=True
            )

            ax.add_artist(asset_legend)

            # 事件颜色说明
            event_handles = [
                Line2D(
                    [0],
                    [0],
                    color="red",
                    linestyle="--",
                    linewidth=1.5,
                    label="Hard threat"
                ),
                Line2D(
                    [0],
                    [0],
                    color="green",
                    linestyle="--",
                    linewidth=1.5,
                    label="Softening / pause / deal"
                )
            ]

            ax.legend(
                handles=event_handles,
                title="Event Type",
                loc="upper right",
                frameon=True
            )

            # 底部说明
            fig.text(
                0.01,
                0.01,
                "Note: Prices are normalized to 100. Event markers are for educational analysis only, not investment advice.",
                fontsize=8,
                alpha=0.75
            )

            plt.tight_layout(rect=[0, 0.04, 1, 1])
            plt.savefig(OUTPUT_FILE, dpi=180)
            plt.show()
            plt.close(fig)

            print("优化版事件标注图已保存到：")
            print(OUTPUT_FILE)