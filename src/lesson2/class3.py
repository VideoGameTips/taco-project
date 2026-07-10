
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_FILE = PROJECT_ROOT / "data" / "market_data_2018_2025.csv"
OUTPUT_FILE = PROJECT_ROOT / "data" / "four_assets_normalized.png"

if not DATA_FILE.exists():
    print("没有找到市场数据文件：", DATA_FILE)
else:
    df = pd.read_csv(DATA_FILE, parse_dates=["date"])
    df = df.set_index("date")

    required_columns = {
        "USO_Close": "USO",
        "GLD_Close": "GLD",
        "SPY_Close": "SPY",
        "QQQ_Close": "QQQ",
    }

    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        print("缺少列：", missing)
    else:
        price_df = df[list(required_columns)].copy()
        price_df.columns = list(required_columns.values())
        price_df = price_df.dropna()

        price_df_norm = price_df / price_df.iloc[0] * 100

        colors = {"USO": "#1f77b4", "GLD": "#2ca02c", "SPY": "#ff7f0e", "QQQ": "#d62728"}
        fig, ax = plt.subplots(figsize=(12, 6))

        for ticker, color in colors.items():
            ax.plot(price_df_norm.index, price_df_norm[ticker], label=ticker, color=color)

        ax.axhline(y=100, color="black", linestyle="--", linewidth=1)
        ax.set_title("Normalized Price Comparison", fontsize=16)
        ax.set_xlabel("Date", fontsize=12)
        ax.set_ylabel("Normalized Price (Base = 100)", fontsize=12)
        ax.legend()
        plt.tight_layout()
        plt.savefig(OUTPUT_FILE, dpi=300)
        print(f"Saved plot to {OUTPUT_FILE}")