import pandas as pd

def load_data():
    return pd.read_csv("High Dimension Dataset/supply_chain_dataset1.csv", parse_dates=["Date"])