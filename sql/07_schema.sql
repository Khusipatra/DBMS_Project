USE supply_chain;

DROP TABLE IF EXISTS daily_record;
DROP TABLE IF EXISTS sku_warehouse;
DROP TABLE IF EXISTS region;
DROP TABLE IF EXISTS supplier;
DROP TABLE IF EXISTS warehouse;
DROP TABLE IF EXISTS product;

CREATE TABLE product (
    sku_id        VARCHAR(10) PRIMARY KEY
);

CREATE TABLE warehouse (
    warehouse_id  VARCHAR(10) PRIMARY KEY
);

CREATE TABLE supplier (
    supplier_id   VARCHAR(10) PRIMARY KEY
);

CREATE TABLE region (
    region_name   VARCHAR(10) PRIMARY KEY
);

CREATE TABLE sku_warehouse (
    sku_id          VARCHAR(10)   NOT NULL,
    warehouse_id    VARCHAR(10)   NOT NULL,
    supplier_id     VARCHAR(10)   NOT NULL,
    lead_time_days  INT           NOT NULL,
    reorder_point   INT           NOT NULL,
    unit_cost       DECIMAL(10,2) NOT NULL,
    unit_price      DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (sku_id, warehouse_id),
    FOREIGN KEY (sku_id)       REFERENCES product(sku_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouse(warehouse_id),
    FOREIGN KEY (supplier_id)  REFERENCES supplier(supplier_id),
    CHECK (lead_time_days > 0),
    CHECK (reorder_point >= 0),
    CHECK (unit_cost > 0),
    CHECK (unit_price >= unit_cost)
);

CREATE TABLE daily_record (
    record_date      DATE          NOT NULL,
    sku_id           VARCHAR(10)   NOT NULL,
    warehouse_id     VARCHAR(10)   NOT NULL,
    region_name      VARCHAR(10)   NOT NULL,
    units_sold       INT           NOT NULL,
    inventory_level  INT           NOT NULL,
    order_quantity   INT           NOT NULL DEFAULT 0,
    promotion_flag   TINYINT       NOT NULL,
    demand_forecast  DECIMAL(10,2),
    PRIMARY KEY (record_date, sku_id, warehouse_id),
    FOREIGN KEY (sku_id, warehouse_id) REFERENCES sku_warehouse(sku_id, warehouse_id),
    FOREIGN KEY (region_name) REFERENCES region(region_name),
    CHECK (units_sold >= 0),
    CHECK (inventory_level >= 0),
    CHECK (order_quantity >= 0),
    CHECK (promotion_flag IN (0, 1))
);

SHOW TABLES;