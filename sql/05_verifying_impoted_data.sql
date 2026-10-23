USE supply_chain;

SELECT COUNT(*) AS total_rows FROM raw;

SELECT MIN(`Date`) AS first_day,
       MAX(`Date`) AS last_day,
       COUNT(DISTINCT SKU_ID)       AS skus,
       COUNT(DISTINCT Warehouse_ID) AS warehouses,
       COUNT(DISTINCT Supplier_ID)  AS suppliers
FROM raw;
