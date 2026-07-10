# Lesson 2 Analysis Scripts

This folder contains the working Python scripts used to clean TACO data, merge news and market datasets, and generate analysis charts.

Run scripts from the repository root so relative project paths resolve correctly:

```bash
python src/lesson2/claimdata.py
python src/lesson2/mergenews.py
python src/lesson2/domainAnalize.py
python src/lesson2/heatmap.py
python src/lesson2/correlation.py
python src/lesson2/taco_events.py
python src/lesson2/taco_events2.py
```

## Script Groups

- Data cleaning and merging: `claimdata.py`, `mergenews.py`, `format-rag.py`.
- TACO case checks: `checkcases.py`, `class3.py`, `class4now.py`, `ground_0.py`.
- Charts and analysis: `domainAnalize.py`, `heatmap.py`, `correlation.py`, `boxplottaco.py`, `sctr_hrd-n_USO.py`, `taco_events.py`, `taco_events2.py`.
- Side experiment: `turtle_bitcoin.py`.

Outputs are written to `data/`.
