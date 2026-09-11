# Supply Chain Demand Forecasting and Explainable Inventory Optimization

End-to-end supply-chain analytics system: MySQL for storage, SQL for historical
analytics, ARIMA/SARIMAX/LSTM/ensemble for demand forecasting, conformal
prediction for uncertainty, and a rule-based framework converting forecasts
into inventory metrics and risk levels.

## 1. Business Problem

Retailers and distributors need to know four things, in order:
**What happened? → What will happen? → How uncertain is that forecast? → What
is the resulting inventory risk?** This project answers all four using one
coherent pipeline, and stops there — it does not tell anyone what to buy.

## 2. Dataset

[High-Dimensional Supply Chain Inventory Dataset](https://www.kaggle.com/datasets/ziya07/high-dimensional-supply-chain-inventory-dataset)
(Kaggle), 91,250 rows, 

## 3. Technology Stack

Python, MySQL 8.0, Pandas, NumPy, Matplotlib, Seaborn, Plotly, Statsmodels,
Scikit-learn, TensorFlow/Keras, SQLAlchemy + mysql-connector-python,
Streamlit.
