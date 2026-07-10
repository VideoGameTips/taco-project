# What Does This Project Do?

The TACO Project is a data-analysis project that studies how Trump-related news, policy statements, and market events may connect to changes in financial markets. It takes messy political and financial news data, organizes it into cleaner datasets, combines it with market price data, and creates charts that make the patterns easier to understand.

At the center of the project is the idea of a TACO case. A case represents a specific news or policy event, such as a tariff threat, trade-war announcement, Federal Reserve comment, recession warning, inflation story, or other headline that could affect markets. Each case can include a date, topic area, market outcome, and a hardness score. The hardness score appears to describe how strong, aggressive, or market-moving the event was.

The project compares these events against asset returns. For example, it looks at how oil, gold, stocks, and tech indexes moved after certain types of headlines. This helps answer questions like whether aggressive tariff language lined up with market declines, whether gold behaved differently during political stress, or whether some topics were more connected to market reactions than others.

The `data/` folder stores the main research material. It includes raw news exports, cleaned news data, market data from 2018 to 2025, merged news-market datasets, TACO case files, and generated visualizations. The `data/raw_queries/` folder preserves original search-result CSVs so the analysis can be traced back to the earlier query batches.

The `src/` folder contains Python scripts that do the work. Some scripts fetch news, some clean article data, some merge news with market data, and others generate charts. The chart outputs include event timelines, correlation heatmaps, asset comparison plots, domain summaries, and boxplots comparing TACO-style cases with hold outcomes.

The project also has placeholder folders for future expansion. The `app/` folder is reserved for a possible dashboard or web presentation. The `docs/` folder is for methodology notes and written explanations. The `notebooks/` folder is for exploratory Jupyter notebooks.

In short, this project turns political and financial headlines into organized research data. It is useful for exploring how news narratives, policy threats, and market behavior may relate to one another. It is an educational research project, not financial advice.
