WITH ranked AS (
    SELECT sku_id, warehouse_id, model_name, wape_pct,
           RANK() OVER (PARTITION BY sku_id, warehouse_id ORDER BY wape_pct) AS rk
    FROM vw_forecast_accuracy
)
SELECT sku_id, warehouse_id, model_name AS best_model, wape_pct
FROM ranked
WHERE rk = 1
ORDER BY sku_id, warehouse_id;