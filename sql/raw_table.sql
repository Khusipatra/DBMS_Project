CREATE DATABASE IF NOT EXISTS supply_chain;
USE supply_chain;

CREATE TABLE raw (
    `Date`                   DATE,
    SKU_ID                   VARCHAR(10),
    Warehouse_ID             VARCHAR(10),
    Supplier_ID              VARCHAR(10),
    Region                   VARCHAR(10),
    Units_Sold               INT,
    Inventory_Level          INT,
    Supplier_Lead_Time_Days  INT,
    Reorder_Point            INT,
    Order_Quantity           INT,
    Unit_Cost                DECIMAL(10,2),
    Unit_Price               DECIMAL(10,2),
    Promotion_Flag           TINYINT,
    Stockout_Flag            TINYINT,
    Demand_Forecast          DECIMAL(10,2)
);

SELECT COUNT(*) AS rows_in_raw FROM raw;