# app.py  -  small Streamlit dashboard for the supply chain project
# Run from the repo root:   streamlit run app.py
import os
import pandas as pd
import matplotlib.pyplot as plt
import streamlit as st
from urllib.parse import quote_plus
from sqlalchemy import create_engine, text

st.set_page_config(page_title="Supply Chain Risk", layout="wide")
st.title("Supply Chain: Forecast and Inventory Risk")

# ---------------------------------------------------------------- connection
st.sidebar.header("MySQL connection")
password = st.sidebar.text_input("Password", type="password",
                                 value=os.environ.get("MYSQL_PASSWORD", ""))
if not password:
    st.info("Type your MySQL password in the sidebar to start.")
    st.stop()

@st.cache_resource
def get_engine(pw):
    return create_engine(f"mysql+pymysql://root:{quote_plus(pw)}@localhost/supply_chain")

engine = get_engine(password)

@st.cache_data
def run_query(sql, params=None):
    return pd.read_sql(text(sql), engine, params=params or {})

COLOURS = {"RED": "#f8b4b4", "YELLOW": "#fde68a", "GREEN": "#bbf7d0"}

def colour_risk(df):
    """colour the 'risk' column red / yellow / green"""
    styler = df.style
    paint = styler.map if hasattr(styler, "map") else styler.applymap
    return paint(lambda v: f"background-color: {COLOURS.get(v, '')}", subset=["risk"])

try:
    tab3, tab1, tab2 = st.tabs(["Risk of all 250 series", "Risk of the 10 forecast series", "Forecast"])

    # ------------------------------------------------------------ tab 1
    with tab1:
        st.subheader("Inventory risk on 30 Nov 2024 (forecast based)")
        st.caption("RED: days of stock < lead time.  YELLOW: stock < reorder point.  GREEN: otherwise.")
        dash = run_query("""SELECT * FROM vw_risk_dashboard
                            ORDER BY FIELD(risk,'RED','YELLOW','GREEN'), days_of_stock""")
        c1, c2, c3 = st.columns(3)
        c1.metric("RED", int((dash["risk"] == "RED").sum()))
        c2.metric("YELLOW", int((dash["risk"] == "YELLOW").sum()))
        c3.metric("GREEN", int((dash["risk"] == "GREEN").sum()))
        st.dataframe(colour_risk(dash), use_container_width=True)

    # ------------------------------------------------------------ tab 2
    with tab2:
        st.subheader("Forecast for December 2024 vs what really sold")
        series = run_query("SELECT DISTINCT sku_id, warehouse_id FROM forecast ORDER BY sku_id, warehouse_id")
        names = (series["sku_id"] + " / " + series["warehouse_id"]).tolist()
        pick = st.selectbox("Product / warehouse", names)
        sku, wh = pick.split(" / ")

        f = run_query("""SELECT forecast_date, model_name, forecast_units, lower_80, upper_80, actual_units
                         FROM forecast WHERE sku_id = :s AND warehouse_id = :w
                         ORDER BY forecast_date""", {"s": sku, "w": wh})
        model = st.radio("Show intervals for", ["ARIMA", "SARIMAX"], horizontal=True)

        fig, ax = plt.subplots(figsize=(10, 4))
        one = f[f["model_name"] == "Naive"]
        ax.plot(one["forecast_date"], one["actual_units"], color="black", label="actual")
        for m, col in [("Naive", "tab:orange"), ("ARIMA", "tab:blue"), ("SARIMAX", "tab:green")]:
            g = f[f["model_name"] == m]
            ax.plot(g["forecast_date"], g["forecast_units"], color=col, label=m)
        g = f[f["model_name"] == model]
        ax.fill_between(g["forecast_date"], g["lower_80"], g["upper_80"], alpha=0.2, label=f"{model} 80% interval")
        ax.legend(); ax.tick_params(axis="x", rotation=30)
        st.pyplot(fig)

        acc = run_query("""SELECT model_name,
                                  ROUND(AVG(ABS(actual_units - forecast_units)), 2) AS mae,
                                  ROUND(100 * SUM(ABS(actual_units - forecast_units)) / SUM(actual_units), 1) AS wape_pct
                           FROM forecast WHERE sku_id = :s AND warehouse_id = :w
                           GROUP BY model_name ORDER BY wape_pct""", {"s": sku, "w": wh})
        st.write("Error of each model for this series (lower is better):")
        st.dataframe(acc, use_container_width=True)

    # ------------------------------------------------------------ tab 3
    with tab3:
        st.subheader("Risk of every product-warehouse pair (based on the last 90 days of actual sales)")
        trend = run_query("""SELECT record_date, SUM(risk = 'RED') AS red, SUM(risk = 'YELLOW') AS yellow
                             FROM vw_risk_daily GROUP BY record_date ORDER BY record_date""")
        st.write("Number of RED and YELLOW series on each day:")
        st.line_chart(trend.set_index("record_date")[["red", "yellow"]], color=["#dc2626", "#eab308"])

        d = st.date_input("Date", value=pd.Timestamp("2024-05-22"),
                          min_value=pd.Timestamp("2024-03-30"), max_value=pd.Timestamp("2024-12-30"))
        day = run_query("""SELECT sku_id, warehouse_id, inventory_level, lead_time_days,
                                  avg_daily_demand, days_of_stock, reorder_point, risk
                           FROM vw_risk_daily WHERE record_date = :d
                           ORDER BY FIELD(risk,'RED','YELLOW','GREEN'), days_of_stock""", {"d": str(d)})
        c1, c2, c3 = st.columns(3)
        c1.metric("RED", int((day["risk"] == "RED").sum()))
        c2.metric("YELLOW", int((day["risk"] == "YELLOW").sum()))
        c3.metric("GREEN", int((day["risk"] == "GREEN").sum()))
        only = st.checkbox("Show only RED and YELLOW", value=False)
        shown = day[day["risk"] != "GREEN"] if only else day
        st.dataframe(colour_risk(shown), use_container_width=True)
        st.caption("Try 2024-11-30 (all GREEN) and 2024-05-22 (red and yellow series).")

except Exception as e:
    st.error(f"Could not read from MySQL: {e}")
