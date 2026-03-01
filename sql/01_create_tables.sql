-- Script 01_create_tables.sql
-- Création de la table des ventes

CREATE TABLE ventes (
    transaction_id VARCHAR(10) PRIMARY KEY,
    date DATE NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    gender VARCHAR(10),
    age INT,
    product_category VARCHAR(50),
    quantity INT,
    price_per_unit DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);