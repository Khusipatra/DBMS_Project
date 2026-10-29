# Supply Chain Demand Forecasting & Inventory Risk

A DBMS course project. It stores supply chain data in MySQL, forecasts demand for 10 product-warehouse series, and flags inventory risk as RED, YELLOW or GREEN.

## What it does
1. Loads 91,250 daily records (250 product-warehouse pairs x 365 days) into a normalized MySQL database.
2. Forecasts the last 30 days (December 2024) for 10 series with Naive, ARIMA and SARIMAX, with 80% prediction intervals.
3. Calculates safety stock, reorder point and days of stock, and gives each series a risk colour.
4. Shows everything in a small Streamlit app that reads from MySQL.

## Files
- `data_understanding.ipynb`, `data_cleaning.ipynb`: explore and check the data
- `01_create_database.sql`, `raw_table.sql`, `03_importing_data.sql`, `05_verifying_impoted_data.sql`, `06_dependency_check.sql`: database setup and checks
- `07_schema.sql`, `09_fill_tables.sql`: create and fill the 8 tables
- `forecasting.ipynb`: forecasts and model scores
- `inventory_analytics.ipynb`: safety stock, reorder point, risk
- `10_views_and_analysis.sql`: views, index, window-function queries
- `app.py`: Streamlit app
- `utils.py`: loads the dataset
- `docs/screenshots/`: query results

## Results
| Model | MAE | WAPE % |
|---|---|---|
| Naive | 5.22 | 29.1 |
| ARIMA | 5.40 | 30.1 |
| SARIMAX | 5.68 | 31.7 |

- Daily demand is noisy, so the simple Naive baseline is hard to beat. The 80% intervals contain about 77 to 79% of actual values and are used for safety stock.
- Risk rule: RED if days of stock < supplier lead time, YELLOW if stock < reorder point, otherwise GREEN.
- All 10 forecast series are GREEN in December. Over all 250 series, on 22 May 2024 there are 21 RED, 16 YELLOW and 213 GREEN.

## How to run
1. Install Python 3 and MySQL 8, then: `pip install pandas numpy matplotlib statsmodels sqlalchemy pymysql streamlit`
2. Run the SQL files in order (`01`, `raw_table`, `03`, `05`, `06`, `07`, `09`), then `10_views_and_analysis.sql`.
3. Run `forecasting.ipynb`, then `inventory_analytics.ipynb`. Run notebooks from the repo root.
4. Start the app: `python -m streamlit run app.py` and type your MySQL password in the sidebar.

## Budget purchase plan (fractional knapsack) - planned
The inventory step says *what is at risk*. The next question is *what to buy when the budget is limited*. This is a fractional knapsack problem:
- For each series, the units needed = max(0, forecast demand - current stock).
- Cost = units needed x unit cost. Profit = units needed x (unit price - unit cost).
- Rank the series by profit per unit of money spent (profit / cost), buy the best ones fully until the budget runs out, then buy a fraction of the last one.
- The design and a worked example are in `fractional_knapsack_report.md`. It is not coded yet.

## Future work
- Forecast all 250 series, not only 10.
- Budget-limited purchase plan using the fractional knapsack (see `fractional_knapsack_report.md`).
- Try LSTM once more history is available.
- Use a simple order-quantity rule (EOQ) and supplier delays in the risk rule.

## License
MIT
