-- ==========================================================
-- MIGRATION FINALE - Gestion auto des IDs avec IDENTITY et SEQUENCE
-- Description : 
--   - transaction_id : INT IDENTITY (auto-incrémenté)
--   - customer_id : INT avec SEQUENCE (démarre à 1000)
--   - Vue ventes_presentation : ajoute préfixes tr_/cu_ et format 5 chiffres
-- ==========================================================

-- PARTIE 0 : Supprimer la contrainte DEFAULT qui référence la séquence
DECLARE @default_constraint_name NVARCHAR(200);
SELECT @default_constraint_name = name
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID('ventes') 
  AND definition LIKE '%customer_seq%';

IF @default_constraint_name IS NOT NULL
    EXEC('ALTER TABLE ventes DROP CONSTRAINT ' + @default_constraint_name);
GO


-- PARTIE 0.1 : Supprimer la séquence si elle existe
IF EXISTS (SELECT * FROM sys.sequences WHERE name = 'customer_seq')
    DROP SEQUENCE customer_seq;
GO


-- PARTIE 1 : Supprimer l'ancienne clé primaire
DECLARE @constraint_name NVARCHAR(200);
SELECT @constraint_name = name
FROM sys.key_constraints
WHERE type = 'PK' AND parent_object_id = OBJECT_ID('ventes');

IF @constraint_name IS NOT NULL
    EXEC('ALTER TABLE ventes DROP CONSTRAINT ' + @constraint_name);
GO


-- PARTIE 2 : Créer la séquence pour customer_id
CREATE SEQUENCE customer_seq
    AS INT
    START WITH 1000
    INCREMENT BY 1;
GO


-- PARTIE 3 : Supprimer l'ancienne table temporaire si elle existe
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ventes_new')
    DROP TABLE ventes_new;
GO


-- PARTIE 4 : Créer la nouvelle table
CREATE TABLE ventes_new (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    date DATE NOT NULL,
    customer_id INT DEFAULT (NEXT VALUE FOR customer_seq),
    gender VARCHAR(10),
    age INT,
    product_category VARCHAR(50),
    quantity INT,
    price_per_unit DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);
GO


-- PARTIE 5 : Copier les données
INSERT INTO ventes_new (
    date, gender, age, product_category, quantity, price_per_unit, total_amount
)
SELECT
    date, gender, age, product_category, quantity, price_per_unit, total_amount
FROM ventes;
GO


-- PARTIE 6 : Supprimer l'ancienne table
DROP TABLE ventes;
GO


-- PARTIE 7 : Renommer la nouvelle table
EXEC sp_rename 'ventes_new', 'ventes';
GO


-- PARTIE 8 : Supprimer l'ancienne vue si elle existe
IF EXISTS (SELECT * FROM sys.views WHERE name = 'ventes_presentation')
    DROP VIEW ventes_presentation;
GO


-- PARTIE 9 : Créer la vue de présentation
CREATE VIEW ventes_presentation AS
SELECT 
    CONCAT('tr_', FORMAT(transaction_id, '00000')) AS transaction_id_display,
    transaction_id AS transaction_id_numeric,
    date,
    CONCAT('cu_', FORMAT(customer_id, '00000')) AS customer_id_display,
    customer_id AS customer_id_numeric,
    gender,
    age,
    product_category,
    quantity,
    price_per_unit,
    total_amount
FROM ventes;
GO


-- PARTIE 10 : Vérifications
SELECT COUNT(*) AS [Total lignes dans ventes] FROM ventes;
SELECT TOP 10 * FROM ventes_presentation ORDER BY transaction_id_numeric;
GO