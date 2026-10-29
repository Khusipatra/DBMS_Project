USE supply_chain;

INSERT INTO product (sku_id)
SELECT DISTINCT SKU_ID FROM raw;

INSERT INTO warehouse (warehouse_id)
SELECT DISTINCT Warehouse_ID FROM raw;

INSERT INTO supplier (supplier_id)
SELECT DISTINCT Supplier_ID FROM raw;

INSERT INTO region (region_name)
SELECT DISTINCT Region FROM raw;

INSERT INTO sku_warehouse
    (sku_id, warehouse_id, supplier_id, lead_time_days, reorder_point, unit_cost, unit_price)
SELECT SKU_ID, Warehouse_ID, MAX(Supplier_ID), MAX(Supplier_Lead_Time_Days),
       MAX(Reorder_Point), MAX(Unit_Cost), MAX(Unit_Price)
FROM raw
GROUP BY SKU_ID, Warehouse_ID;

INSERT INTO daily_record
    (record_date, sku_id, warehouse_id, region_name, units_sold,
     inventory_level, order_quantity, promotion_flag, demand_forecast)
SELECT Date, SKU_ID, Warehouse_ID, Region, Units_Sold,
       Inventory_Level, Order_Quantity, Promotion_Flag, Demand_Forecast
FROM raw;

