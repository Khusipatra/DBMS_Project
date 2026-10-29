USE Supply_chain;
CREATE OR REPLACE VIEW vw_risk_daily AS
WITH roll AS (
    SELECT d.record_date, d.sku_id, d.warehouse_id, d.inventory_level, s.lead_time_days,
           AVG(d.units_sold)         OVER w AS avg_d,
           STDDEV_SAMP(d.units_sold) OVER w AS sd_d,
           COUNT(*)                  OVER w AS n
    FROM daily_record d
    JOIN sku_warehouse s
      ON s.sku_id = d.sku_id AND s.warehouse_id = d.warehouse_id
    WINDOW w AS (PARTITION BY d.sku_id, d.warehouse_id
                 ORDER BY d.record_date ROWS BETWEEN 89 PRECEDING AND CURRENT ROW)
)
SELECT record_date, sku_id, warehouse_id, inventory_level, lead_time_days,
       ROUND(avg_d, 1)                                                        AS avg_daily_demand,
       ROUND(inventory_level / avg_d, 1)                                      AS days_of_stock,
       ROUND(avg_d * lead_time_days + 1.65 * sd_d * SQRT(lead_time_days), 1)  AS reorder_point,
       CASE WHEN inventory_level / avg_d < lead_time_days THEN 'RED'
            WHEN inventory_level < avg_d * lead_time_days + 1.65 * sd_d * SQRT(lead_time_days) THEN 'YELLOW'
            ELSE 'GREEN' END                                                  AS risk
FROM roll
WHERE n = 90;