import pandas as pd
from pathlib import Path
import time

# 当前文件在 src/lesson4 中
# parents[2] 回到 TACO_Project 根目录
PROJECT_ROOT = Path(__file__).resolve().parents[2]

# 案例库通常放在项目根目录
CASES_FILE = PROJECT_ROOT / "data" / "taco_cases.csv"

if not CASES_FILE.exists():
    print("did not find taco_cases.csv")
    print("check file location")
    print(CASES_FILE)
else:
    df = pd.read_csv(CASES_FILE, parse_dates = ["date"])
    df["result"] = df["result"].replace({"NOT_TACO":"HOLD"})
    print("data:")
    time.sleep(0.2)
    print(df.head())
    time.sleep(0.2)
    print(df.columns)
    time.sleep(0.2)
    print(df["result"].value_counts())
    time.sleep(0.2)
    print(df["domain"].value_counts())
    time.sleep(0.2)
    print(df["hardness"].describe())
