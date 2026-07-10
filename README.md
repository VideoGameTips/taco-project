# TACO Project

TACO is a data-analysis project for studying how Trump-related news and policy signals line up with market moves. The project collects news, cleans it, combines it with market data, scores TACO cases, and generates charts for presentation.

## Goals

1. Collect finance and policy news from RSS/news queries.
2. Clean and organize raw news data.
3. Build a TACO case dataset with event dates, domains, hardness scores, and asset returns.
4. Analyze relationships between news domains and market moves.
5. Prepare outputs that can later power a small web presentation app.

## Project Structure

- `data/` - curated datasets, merged analysis tables, generated charts, and raw query exports.
- `data/raw_queries/` - original Trump/news query CSV exports preserved for traceability.
- `src/` - Python scripts for scraping, cleaning, merging, scoring, plotting, and experiments.
- `src/lesson2/` - classroom/lesson analysis scripts and examples.
- `app/` - future web app or dashboard files.
- `docs/` - project notes and writeups.
- `notebooks/` - future exploratory Jupyter notebooks.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Common Scripts

Run these commands from the repository root.

```bash
python src/lesson2/claimdata.py
python src/lesson2/mergenews.py
python src/lesson2/heatmap.py
python src/lesson2/correlation.py
python src/lesson2/taco_events.py
python src/lesson2/taco_events2.py
```

The scripts read from `data/` and write cleaned CSVs or charts back into `data/`.

## Key Outputs

- `data/clean_news.csv` - cleaned news dataset.
- `data/merged_news_market.csv` - news joined with market data.
- `data/domain_summary.csv` - grouped domain-level analysis.
- `data/correlation_heatmap.png` - correlation chart for event hardness and asset returns.
- `data/taco_events.png` and `data/taco_events_better.png` - event visualizations.

## Notes

This is an educational research project, not financial advice. Raw exports are kept so results can be traced back to the original search batches.
