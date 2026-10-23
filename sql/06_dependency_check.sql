USE supply_chain;

SELECT '1. Duplicate groups on (Date, SKU, Warehouse)' AS test, COUNT(*) AS result
FROM (SELECT 1 FROM raw GROUP BY `Date`, SKU_ID, Warehouse_ID HAVING COUNT(*) > 1) t

UNION ALL
SELECT '2a. Groups with duplicates if Warehouse is dropped', COUNT(*)
FROM (SELECT 1 FROM raw GROUP BY `Date`, SKU_ID HAVING COUNT(*) > 1) t

UNION ALL
SELECT '2b. Groups with duplicates if SKU is dropped', COUNT(*)
FROM (SELECT 1 FROM raw GROUP BY `Date`, Warehouse_ID HAVING COUNT(*) > 1) t

UNION ALL
SELECT '2c. Groups with duplicates if Date is dropped', COUNT(*)
FROM (SELECT 1 FROM raw GROUP BY SKU_ID, Warehouse_ID HAVING COUNT(*) > 1) t

UNION ALL
SELECT '3a. SKU-warehouse pairs where a fixed column changes', COUNT(*)
FROM (SELECT 1 FROM raw GROUP BY SKU_ID, Warehouse_ID
      HAVING COUNT(DISTINCT Supplier_ID) > 1
          OR COUNT(DISTINCT Supplier_Lead_Time_Days) > 1
          OR COUNT(DISTINCT Reorder_Point) > 1
          OR COUNT(DISTINCT Unit_Cost) > 1
          OR COUNT(DISTINCT Unit_Price) > 1) t

UNION ALL
SELECT '3b. Max distinct Regions within one pair', MAX(n)
FROM (SELECT COUNT(DISTINCT Region) AS n FROM raw GROUP BY SKU_ID, Warehouse_ID) t

UNION ALL
SELECT '4a. Max distinct suppliers for one SKU', MAX(n)
FROM (SELECT COUNT(DISTINCT Supplier_ID) AS n FROM raw GROUP BY SKU_ID) t

UNION ALL
SELECT '4b. Max distinct lead times for one supplier', MAX(n)
FROM (SELECT COUNT(DISTINCT Supplier_Lead_Time_Days) AS n FROM raw GROUP BY Supplier_ID) t;