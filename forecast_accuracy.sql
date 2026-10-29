CREATE OR REPLACE VIEW vw_forecast_accuracy AS
SELECT sku_id, warehouse_id, model_name,
       ROUND(AVG(ABS(actual_units - forecast_units)), 2)                           AS mae,
       ROUND(100 * SUM(ABS(actual_units - forecast_units)) / SUM(actual_units), 1) AS wape_pct,
       ROUND(100 * AVG(CASE WHEN lower_80 IS NULL THEN NULL
                            WHEN actual_units BETWEEN lower_80 AND upper_80 THEN 1
                            ELSE 0 END), 1)                                         AS inside_80_pct
FROM forecast
GROUP BY sku_id, warehouse_id, model_name;

-- C1. score of each model over all 10 series (lower WAPE = better)
SELECT model_name,
       ROUND(AVG(ABS(actual_units - forecast_units)), 2)                           AS mae,
       ROUND(100 * SUM(ABS(actual_units - forecast_units)) / SUM(actual_units), 1) AS wape_pct
FROM forecast
GROUP BY model_name
ORDER BY wape_pct;