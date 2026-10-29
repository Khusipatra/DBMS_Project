CREATE OR REPLACE VIEW vw_risk_dashboard AS
SELECT ia.sku_id, ia.warehouse_id, sw.supplier_id, sw.lead_time_days,
       ia.current_stock, ia.avg_daily_demand, ia.safety_stock, ia.reorder_point,
       ia.days_of_stock, ia.risk
FROM inventory_analytics ia
JOIN sku_warehouse sw
  ON sw.sku_id = ia.sku_id AND sw.warehouse_id = ia.warehouse_id;

SELECT * FROM vw_risk_dashboard
ORDER BY FIELD(risk, 'RED', 'YELLOW', 'GREEN'), days_of_stock;