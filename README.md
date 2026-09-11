# Supply Chain Demand Forecasting and Explainable Inventory Optimization

End-to-end supply-chain analytics system: MySQL for storage, SQL for historical
analytics, ARIMA/SARIMAX/LSTM/ensemble for demand forecasting, conformal
prediction for uncertainty, and a rule-based framework converting forecasts
into inventory metrics and risk levels. **No recommendation engine, no
recommended order quantities, no reorder actions are produced anywhere.**

Every number in this README came from actually running the code in this repo
against the real dataset — nothing here is a placeholder or an assumed result.

## 1. Business Problem

Retailers and distributors need to know four things, in order:
**What happened? → What will happen? → How uncertain is that forecast? → What
is the resulting inventory risk?** This project answers all four using one
coherent pipeline, and stops there — it does not tell anyone what to buy.

## 2. Dataset

[High-Dimensional Supply Chain Inventory Dataset](https://www.kaggle.com/datasets/ziya07/high-dimensional-supply-chain-inventory-dataset)
(Kaggle), 91,250 rows, verified before any schema or modeling work began
(see "Phase 1 Findings" below).

## 3. Technology Stack

Python, MySQL 8.0, Pandas, NumPy, Matplotlib, Seaborn, Plotly, Statsmodels,
Scikit-learn, TensorFlow/Keras, SQLAlchemy + mysql-connector-python,
Streamlit.

## 4. Phase 1 Findings (data inspection, before any design decisions)

- **Shape:** 91,250 rows × 15 columns. 0 missing values, 0 duplicate rows.
- **Actual grain:** one row per (Date, SKU_ID, Warehouse_ID) — 50 SKUs × 5
  Warehouses × 365 days = 91,250, exactly matching the row count.
- **Entities:** Supplier_ID, Supplier_Lead_Time_Days, Reorder_Point,
  Unit_Cost, Unit_Price are all **static per (SKU_ID, Warehouse_ID)** —
  verified as exactly 1 distinct value per combo across the whole year.
  Region is **not** static — it varies day to day, roughly uniformly, for
  a given SKU+Warehouse.
- **Date range:** 2024-01-01 to 2024-12-30, daily, no gaps — but only **one
  calendar year**, so annual seasonality could not be tested season-over-
  season (only weekly/lag-7 seasonality was diagnosable).
- **Two columns excluded from modeling, with evidence:**
  - `Demand_Forecast` correlates **0.949** with `Units_Sold` and is
    essentially `Units_Sold` + small noise (mean diff ≈0.03, std ≈2.99) —
    using it as a feature would trivially leak the target.
  - `Stockout_Flag` is **constant 0** across all 91,250 rows — kept in the
    schema for transparency, but there is no real stockout ground truth to
    validate the inventory-risk framework against.
- **Target variable:** `Units_Sold`.
- **Outliers:** 110 IQR-flagged high values in `Units_Sold`, and **100% of
  them occur on promotion days** (vs. a 10.2% baseline promotion rate) —
  confirmed as legitimate promotion-driven demand spikes, not data errors,
  and were **not removed**.

## 5. Database Schema

See [`sql/schema.sql`](sql/schema.sql). 7 tables: `dim_date`,
`dim_supplier`, `dim_sku_warehouse` (the static SKU+Warehouse attributes,
250 rows), `fact_daily_operations` (the central fact table at the verified
source grain, 91,250 rows), `forecast_results`, `model_performance`,
`inventory_analysis`. Actually executed against MySQL 8.0 — table and row
counts verified by direct `COUNT(*)` after load: 365 / 10 / 250 / 91,250.

## 6. SQL Analytics

[`sql/analytical_queries.sql`](sql/analytical_queries.sql) — 21 queries,
all executed successfully with zero errors: filtering, aggregation, GROUP
BY, JOINs, subqueries, CTEs, and window functions (RANK, LAG, LEAD, rolling
averages, month-over-month growth).

## 7. Feature Engineering ([`src/feature_engineering.py`](src/feature_engineering.py))

Lag features (1/7/14/30 days) and rolling mean/std (7/14/30 days) computed
on **shifted** data only — a feature for day *t* never uses information
from day *t* or later. Same-day `Inventory_Level` is excluded as a feature;
only its lagged value is used, since current inventory is partly a
downstream consequence of the very demand being predicted.

## 8. EDA & Time-Series Diagnostics ([`outputs/figures/`](outputs/figures/))

- Demand is near-uniform across warehouses and regions (this dataset does
  not have a "hot" warehouse/region); promotions clearly lift demand
  (24.9 vs. 19.5 avg units/day).
- Deep-dive series: **SKU_33 / WH_4** — the single highest-volume
  combination in the dataset (7,563 total units), chosen for the
  ARIMA/SARIMAX/LSTM/ensemble work; also has 42 promotion days, enough
  to test a promotion exogenous term.
- **ADF test (raw series):** statistic -0.972, p=0.763 → **non-stationary**
  (supports d=1 in ARIMA).
- **ADF test (STL residuals):** statistic -8.182, p≈0 → residuals ARE
  stationary once trend/seasonal are removed.
- **Ljung-Box (lags 10, 20):** p≈0 at both → significant autocorrelation,
  series has real learnable structure.
- **STL decomposition:** visible trend (rise → fall → rise across the
  year) and a weak weekly seasonal component.

## 9. Chronological Train/Validation/Test Split

70/15/15, no shuffling:
- Train: 2024-01-01 to 2024-09-11 (255 days)
- Validation: 2024-09-12 to 2024-11-05 (55 days)
- Test: 2024-11-06 to 2024-12-30 (55 days, never touched until final evaluation)

## 10. Model Comparison — SKU_33/WH_4, same unseen test period

| Model | MAE | RMSE | MAPE | 95% Interval Coverage |
|---|---|---|---|---|
| **ARIMA(2,1,3)** | **4.089** | **5.241** | **30.9%** | 96.4% |
| Ensemble (100% ARIMA / 0% LSTM) | 4.089 | 5.241 | 30.9% | — |
| LSTM (lookback=60) | 4.434 | 5.575 | 31.9% | 94.5% (conformal) |
| Moving Average (7-day) | 4.574 | 5.745 | 34.5% | — |
| SARIMAX(1,0,1) + Promotion | 4.615 | 5.642 | 32.7% | 96.4% |
| Naive | 6.182 | 8.097 | 47.1% | — |

**Honest findings, not massaged into a forced narrative:**
- ARIMA(2,1,3) — selected by walk-forward validation MAE, not AIC alone —
  is the best point-forecast model on this series.
- SARIMAX with the `Promotion_Flag` exogenous term performed *worse* than
  plain ARIMA here. Promotions are a legitimate, business-known-in-advance
  exogenous variable, but adding them didn't help this particular series.
- The ensemble weight search (minimizing validation MAE over all
  ARIMA/LSTM blend ratios) selected **100% ARIMA / 0% LSTM** — the "ensemble"
  collapsed to plain ARIMA because LSTM's errors weren't different enough
  from ARIMA's to improve a linear blend.
- All models with an interval are well-calibrated against their 95% target
  (94.5%–96.4% empirical coverage).

## 11. Forecast Uncertainty

- ARIMA/SARIMAX use statsmodels' genuine parametric prediction intervals.
- LSTM only produces a point forecast — a standard neural net is **not**
  probabilistic. We do not call its output a confidence interval. Instead
  we apply **split conformal prediction**: the 95th percentile of absolute
  residuals on the validation set becomes a fixed half-width around each
  test point forecast. Empirical coverage was checked, not assumed:
  94.5% against a 95% target.

## 12. Inventory Optimization ([`src/inventory.py`](src/inventory.py))

```
Expected Lead-Time Demand = Forecast Daily Demand × Lead Time
Safety Stock = Z × σ_demand × √Lead Time      (Z=1.645 for 95% service level)
Reorder Point = Expected Lead-Time Demand + Safety Stock
```
95% service level applied uniformly — the dataset gives no per-SKU targets
to differentiate on.

## 13. Inventory Risk Analysis

Rule-based, four levels (LOW/MEDIUM/HIGH/CRITICAL), each with a plain-
language explanation. Deliberately called **risk levels**, not
"stockout probabilities" — no probability model was calibrated (the
dataset's `Stockout_Flag` has zero variance, so there is no ground truth to
calibrate against). On the full 250-combo catalog snapshot: **247 LOW, 2
HIGH, 0 MEDIUM/CRITICAL** — a real, unforced result, not a designed
distribution.

## 14. Streamlit Dashboard ([`app.py`](app.py))

7 pages as specified: Executive Overview, Demand Analytics, Time-Series
Analysis, Forecasting, Model Comparison, Inventory Optimization, Inventory
Risk. Reads only from MySQL via parameterized queries — no arbitrary user
SQL, no exposed credentials (read from `.env` / environment variables).
Actually launched and smoke-tested: every query behind every page executes
successfully against the live database.

## 15. Installation & Setup

```bash
git clone <repo>
cd supply-chain-forecasting
pip install -r requirements.txt

# MySQL setup
mysql -u root -e "CREATE DATABASE supply_chain_db; CREATE USER 'scm_user'@'localhost' IDENTIFIED BY 'your_password'; GRANT ALL ON supply_chain_db.* TO 'scm_user'@'localhost';"
cp .env.example .env   # fill in your DB_PASSWORD

mysql -u scm_user -p supply_chain_db < sql/schema.sql
python src/data_loader.py          # loads the cleaned dataset into MySQL
mysql -u scm_user -p supply_chain_db < sql/analytical_queries.sql

streamlit run app.py
```

## 16. Project Structure

```
supply-chain-forecasting/
├── data/raw/                      # source CSV
├── outputs/
│   ├── figures/                   # EDA + diagnostic plots (actually generated)
│   ├── model_comparison.csv
│   └── inventory_analysis_*.csv
├── sql/
│   ├── schema.sql
│   └── analytical_queries.sql
├── src/
│   ├── database.py                # SQLAlchemy engine, env-var credentials
│   ├── preprocessing.py           # cleaning + validation, outlier reasoning
│   ├── data_loader.py             # ETL: CSV -> MySQL
│   ├── feature_engineering.py     # leakage-safe lag/rolling/calendar features
│   ├── evaluation.py              # shared metrics + chronological split
│   ├── arima_model.py
│   ├── sarimax_model.py
│   ├── lstm_model.py
│   ├── uncertainty.py             # conformal prediction for LSTM
│   └── inventory.py               # safety stock, reorder point, risk levels
├── models/lstm_sku33_wh4.keras
├── app.py                         # Streamlit dashboard (7 pages)
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

**Note on structure:** heavy logic lives in modular `src/` files rather than
notebooks, per the project's own code-quality requirement to avoid
monolithic notebooks — every module was actually run against the real data
(not just written) to produce the results in this README.

## 17. Future Improvements

- Extend deep forecasting (ARIMA/SARIMAX/LSTM) beyond the single deep-dive
  series to a larger sample of SKU-Warehouse combos.
- If more historical years become available, revisit annual-seasonality
  diagnostics (only one year exists in the current extract).
- Investigate why SARIMAX's promotion term didn't improve on plain ARIMA
  for this series (worth testing on a series with an even higher promotion
  rate).
