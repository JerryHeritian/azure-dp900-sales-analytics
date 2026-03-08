-- 06_create_table_agregees.sql
-- Table pour stocker les ventes agrégées par mois et catégorie
-- Créée le 2025-03-08 dans le cadre du Jour 15 (Data Flow)

CREATE TABLE ventes_agregees (
    id INT IDENTITY(1,1) PRIMARY KEY,
    annee INT NOT NULL,
    mois INT NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    total_ventes INT NOT NULL,
    ca_total DECIMAL(12,2) NOT NULL,
    prix_moyen DECIMAL(10,2) NOT NULL,
    date_calcul DATE DEFAULT GETDATE()
);