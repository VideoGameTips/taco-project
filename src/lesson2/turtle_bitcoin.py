#!/usr/bin/env python3
"""
Turtle Bitcoin Predictor

An educational Python app that predicts the next Bitcoin price, measures the
difference from the actual price, and slowly learns from each mistake.

This is not financial advice.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import time
import tkinter as tk
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Iterable
from urllib.error import URLError
from urllib.request import urlopen


COINGECKO_URL = (
    "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart"
    "?vs_currency=usd&days=7&interval=hourly"
)


@dataclass
class PricePoint:
    timestamp: datetime
    price: float


@dataclass
class PredictionStep:
    timestamp: datetime
    prediction: float
    actual: float
    difference: float
    absolute_error: float
    bias: float
    trend: float


class TurtleLearner:
    def __init__(self, learning_rate: float = 0.16, trend_rate: float = 0.24) -> None:
        self.learning_rate = learning_rate
        self.trend_rate = trend_rate
        self.bias = 0.0
        self.trend = 0.0
        self.previous_price: float | None = None
        self.previous_move = 0.0

    def seed(self, price: float) -> None:
        self.previous_price = price

    def predict(self) -> float:
        if self.previous_price is None:
            raise ValueError("Turtle needs a starting price before it can predict.")
        return self.previous_price + self.trend + self.bias

    def learn(self, actual: float, timestamp: datetime) -> PredictionStep:
        prediction = self.predict()
        difference = actual - prediction
        latest_move = actual - (self.previous_price or actual)

        self.bias += self.learning_rate * difference
        self.trend += self.trend_rate * (latest_move - self.trend)
        self.previous_move = latest_move
        self.previous_price = actual

        return PredictionStep(
            timestamp=timestamp,
            prediction=prediction,
            actual=actual,
            difference=difference,
            absolute_error=abs(difference),
            bias=self.bias,
            trend=self.trend,
        )


def fetch_bitcoin_prices() -> list[PricePoint]:
    with urlopen(COINGECKO_URL, timeout=8) as response:
        payload = json.loads(response.read().decode("utf-8"))

    prices = []
    for millis, price in payload.get("prices", []):
        prices.append(
            PricePoint(
                timestamp=datetime.fromtimestamp(millis / 1000),
                price=float(price),
            )
        )
    if len(prices) < 10:
        raise ValueError("CoinGecko returned too few price points.")
    return prices


def demo_prices() -> list[PricePoint]:
    random.seed(21)
    start = datetime.now() - timedelta(hours=95)
    price = 102_500.0
    points = []

    for hour in range(96):
        wave = math.sin(hour / 6) * 460
        shock = random.uniform(-340, 340)
        drift = 28 if hour < 46 else -18
        price = max(20_000, price + wave * 0.08 + shock + drift)
        points.append(PricePoint(timestamp=start + timedelta(hours=hour), price=price))

    return points


def load_prices(use_live_data: bool = True) -> tuple[list[PricePoint], str]:
    if not use_live_data:
        return demo_prices(), "Demo data"

    try:
        return fetch_bitcoin_prices(), "Live CoinGecko data"
    except (OSError, URLError, TimeoutError, ValueError, json.JSONDecodeError):
        return demo_prices(), "Demo data, because live prices were unavailable"


def dollar(value: float) -> str:
    return f"${value:,.2f}"


def signed_dollar(value: float) -> str:
    sign = "+" if value >= 0 else "-"
    return f"{sign}${abs(value):,.2f}"


def average(values: Iterable[float]) -> float:
    values = list(values)
    return sum(values) / len(values) if values else 0.0


def percent_error(step: PredictionStep) -> float:
    if step.actual == 0:
        return 0.0
    return (step.absolute_error / step.actual) * 100


class TurtleBitcoinApp:
    def __init__(self, root: tk.Tk, prices: list[PricePoint], source: str) -> None:
        self.root = root
        self.prices = prices
        self.source = source
        self.index = 1
        self.steps: list[PredictionStep] = []
        self.learner = TurtleLearner()
        self.learner.seed(prices[0].price)
        self.running = True
        self.after_id: str | None = None

        root.title("Turtle Bitcoin Predictor")
        root.geometry("1040x720")
        root.minsize(860, 620)
        root.configure(bg="#101416")

        self.header = tk.Label(
            root,
            text="Turtle Bitcoin Predictor",
            fg="#f2f6ef",
            bg="#101416",
            font=("Helvetica", 26, "bold"),
        )
        self.header.pack(anchor="w", padx=22, pady=(18, 2))

        self.subheader = tk.Label(
            root,
            text=source,
            fg="#9db2aa",
            bg="#101416",
            font=("Helvetica", 12),
        )
        self.subheader.pack(anchor="w", padx=24)

        self.stats = tk.Frame(root, bg="#101416")
        self.stats.pack(fill="x", padx=18, pady=16)

        self.stat_labels = {}
        for name in ["Prediction", "Actual", "Difference", "Abs Error", "Bias", "Trend"]:
            box = tk.Frame(self.stats, bg="#182023", highlightbackground="#2d3a3f", highlightthickness=1)
            box.pack(side="left", fill="x", expand=True, padx=5)
            tk.Label(box, text=name, fg="#8fa19a", bg="#182023", font=("Helvetica", 10)).pack(
                anchor="w", padx=12, pady=(9, 1)
            )
            value = tk.Label(box, text="--", fg="#f2f6ef", bg="#182023", font=("Helvetica", 14, "bold"))
            value.pack(anchor="w", padx=12, pady=(0, 10))
            self.stat_labels[name] = value

        self.canvas = tk.Canvas(root, bg="#0f1719", highlightthickness=0)
        self.canvas.pack(fill="both", expand=True, padx=18, pady=(0, 12))

        self.footer = tk.Frame(root, bg="#101416")
        self.footer.pack(fill="x", padx=18, pady=(0, 14))

        self.status = tk.Label(
            self.footer,
            text="Turtle is warming up...",
            fg="#d4ddd7",
            bg="#101416",
            font=("Helvetica", 12),
        )
        self.status.pack(side="left")

        self.button = tk.Button(
            self.footer,
            text="Pause",
            command=self.toggle,
            bg="#d8f275",
            fg="#101416",
            activebackground="#bfe457",
            activeforeground="#101416",
            relief="flat",
            padx=18,
            pady=8,
            font=("Helvetica", 12, "bold"),
        )
        self.button.pack(side="right")

        self.root.bind("<space>", lambda _event: self.toggle())
        self.root.bind("<Configure>", lambda _event: self.draw_chart())
        self.tick()

    def toggle(self) -> None:
        self.running = not self.running
        self.button.configure(text="Pause" if self.running else "Resume")
        if self.running:
            self.tick()
        elif self.after_id is not None:
            self.root.after_cancel(self.after_id)
            self.after_id = None

    def tick(self) -> None:
        self.after_id = None
        if self.running and self.index < len(self.prices):
            point = self.prices[self.index]
            step = self.learner.learn(point.price, point.timestamp)
            self.steps.append(step)
            self.index += 1
            self.update_stats(step)
            self.draw_chart()

        if self.index >= len(self.prices):
            self.running = False
            self.button.configure(text="Replay", command=self.replay)
            mean_error = average(step.absolute_error for step in self.steps)
            mean_percent = average(percent_error(step) for step in self.steps)
            self.status.configure(text=f"Run complete. Average miss: {dollar(mean_error)} ({mean_percent:.2f}%).")
            return

        if self.running:
            self.after_id = self.root.after(420, self.tick)

    def replay(self) -> None:
        self.index = 1
        self.steps.clear()
        self.learner = TurtleLearner()
        self.learner.seed(self.prices[0].price)
        self.running = True
        self.button.configure(text="Pause", command=self.toggle)
        self.status.configure(text="Turtle is trying again from the beginning...")
        self.tick()

    def update_stats(self, step: PredictionStep) -> None:
        self.stat_labels["Prediction"].configure(text=dollar(step.prediction))
        self.stat_labels["Actual"].configure(text=dollar(step.actual))
        self.stat_labels["Difference"].configure(
            text=signed_dollar(step.difference),
            fg="#9ff2bf" if step.difference >= 0 else "#ff9e9e",
        )
        self.stat_labels["Abs Error"].configure(text=dollar(step.absolute_error))
        self.stat_labels["Bias"].configure(text=signed_dollar(step.bias))
        self.stat_labels["Trend"].configure(text=signed_dollar(step.trend))

        direction = "too low" if step.difference > 0 else "too high"
        self.status.configure(
            text=f"{step.timestamp:%b %d %H:%M}: prediction was {direction} by {dollar(step.absolute_error)}."
        )

    def draw_chart(self) -> None:
        self.canvas.delete("all")
        width = max(self.canvas.winfo_width(), 500)
        height = max(self.canvas.winfo_height(), 300)
        pad_x = 58
        pad_y = 34

        if not self.steps:
            self.canvas.create_text(
                width / 2,
                height / 2,
                text="Waiting for Turtle's first prediction...",
                fill="#8fa19a",
                font=("Helvetica", 16, "bold"),
            )
            return

        actuals = [step.actual for step in self.steps]
        preds = [step.prediction for step in self.steps]
        values = actuals + preds
        low = min(values)
        high = max(values)
        span = max(high - low, 1)

        def xy(i: int, value: float) -> tuple[float, float]:
            x_span = max(len(self.steps) - 1, 1)
            x = pad_x + (width - pad_x * 2) * (i / x_span)
            y = height - pad_y - ((value - low) / span) * (height - pad_y * 2)
            return x, y

        for fraction in [0, 0.25, 0.5, 0.75, 1]:
            y = pad_y + (height - pad_y * 2) * fraction
            self.canvas.create_line(pad_x, y, width - pad_x, y, fill="#1d2a2e")

        self.draw_line([xy(i, value) for i, value in enumerate(preds)], "#f2d16b", 3)
        self.draw_line([xy(i, value) for i, value in enumerate(actuals)], "#74d8ff", 3)

        last = self.steps[-1]
        actual_x, actual_y = xy(len(self.steps) - 1, last.actual)
        pred_x, pred_y = xy(len(self.steps) - 1, last.prediction)
        self.canvas.create_line(actual_x, actual_y, pred_x, pred_y, fill="#ff8c7a", dash=(5, 5), width=2)
        self.canvas.create_oval(actual_x - 5, actual_y - 5, actual_x + 5, actual_y + 5, fill="#74d8ff", outline="")
        self.canvas.create_oval(pred_x - 5, pred_y - 5, pred_x + 5, pred_y + 5, fill="#f2d16b", outline="")

        self.canvas.create_text(pad_x, 18, text="Actual", fill="#74d8ff", anchor="w", font=("Helvetica", 12, "bold"))
        self.canvas.create_text(pad_x + 78, 18, text="Prediction", fill="#f2d16b", anchor="w", font=("Helvetica", 12, "bold"))
        self.canvas.create_text(
            width - pad_x,
            18,
            text=f"Latest gap: {signed_dollar(last.difference)}",
            fill="#f2f6ef",
            anchor="e",
            font=("Helvetica", 12, "bold"),
        )
        self.canvas.create_text(pad_x - 8, pad_y, text=dollar(high), fill="#8fa19a", anchor="e")
        self.canvas.create_text(pad_x - 8, height - pad_y, text=dollar(low), fill="#8fa19a", anchor="e")

    def draw_line(self, points: list[tuple[float, float]], color: str, width: int) -> None:
        if len(points) == 1:
            x, y = points[0]
            self.canvas.create_oval(x - 3, y - 3, x + 3, y + 3, fill=color, outline="")
            return

        flat_points = [coord for point in points for coord in point]
        self.canvas.create_line(*flat_points, fill=color, width=width, smooth=True)


def run_cli(prices: list[PricePoint], source: str, limit: int | None = 20, delay: float = 0.0) -> None:
    learner = TurtleLearner()
    learner.seed(prices[0].price)
    steps: list[PredictionStep] = []
    rows = prices[1 : limit + 1] if limit else prices[1:]

    print(f"Turtle Bitcoin Predictor ({source})")
    print("time,prediction,actual,difference,absolute_error,error_percent,bias,trend")

    for point in rows:
        step = learner.learn(point.price, point.timestamp)
        steps.append(step)
        print(
            f"{step.timestamp.isoformat(timespec='minutes')},"
            f"{step.prediction:.2f},"
            f"{step.actual:.2f},"
            f"{step.difference:.2f},"
            f"{step.absolute_error:.2f},"
            f"{percent_error(step):.3f},"
            f"{step.bias:.2f},"
            f"{step.trend:.2f}"
        )
        if delay:
            time.sleep(delay)

    if steps:
        mean_error = average(step.absolute_error for step in steps)
        mean_percent = average(percent_error(step) for step in steps)
        last = steps[-1]
        print()
        print(f"Average miss: {dollar(mean_error)} ({mean_percent:.2f}%)")
        print(f"Latest prediction gap: {signed_dollar(last.difference)}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Predict Bitcoin prices, compare the prediction to the actual price, and learn from each miss."
    )
    parser.add_argument("--cli", action="store_true", help="print predictions in the terminal instead of opening the GUI")
    parser.add_argument("--demo", action="store_true", help="use built-in demo prices instead of trying live data")
    parser.add_argument("--all", action="store_true", help="show every available CLI row")
    parser.add_argument("--limit", type=int, default=20, help="number of CLI rows to print; use --all for the full stream")
    parser.add_argument("--delay", type=float, default=0.0, help="seconds to pause between CLI rows")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    prices, source = load_prices(use_live_data=not args.demo)

    if args.cli:
        run_cli(prices, source, limit=None if args.all else args.limit, delay=args.delay)
        return 0

    root = tk.Tk()
    TurtleBitcoinApp(root, prices, source)
    root.mainloop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
