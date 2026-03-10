# Projet Azure – Analyse de ventes

## Objectif
Projet pratique pour la certification Microsoft Azure Data Fundamentals (DP‑900).  
Mise en place d'une plateforme de données de bout en bout (End-to-End) sur Azure.

## Structure du projet
- data/raw : données brutes (CSV)
- data/processed : données transformées
- sql : scripts SQL (création, migration, requêtes)
- notebooks : exploration (Python / Jupyter)
- docs : captures d'écran du projet

---

## Architecture technique

### Stockage des données
- Azure SQL Database : Données transactionnelles (ventes)
- Azure Blob Storage : Fichiers non structurés (factures PDF)
- Azure Cosmos DB : Catalogue produits flexible (NoSQL)

### Pipeline de données
- Ingestion : Fichiers CSV → Azure SQL (Azure Data Factory)
- Transformation : Data Flow pour agrégation des ventes
- Orchestration : Pipeline automatisé avec dépendances
- Automatisation : Trigger quotidien à 1h00

### Sécurité
- Accès privé aux conteneurs Blob
- SAS tokens pour accès temporaire
- Pare-feu Azure SQL avec règles IP

---

## Évolution de la base de données

Nous avons modernisé la table ventes avec une architecture plus performante :

- **transaction_id** : VARCHAR (tr_00001) → INT IDENTITY (auto-incrémenté)
- **customer_id** : VARCHAR (cu_01000) → INT avec SEQUENCE
- **Affichage** : Direct dans la table → Via vue ventes_presentation
- **Pipeline ADF** : 9 mappings → 7 mappings simplifiés

```sql
-- Table ventes (stockage physique)
transaction_id INT IDENTITY(1,1) PRIMARY KEY,
customer_id INT DEFAULT (NEXT VALUE FOR customer_seq),
date DATE NOT NULL,
gender VARCHAR(10),
age INT,
product_category VARCHAR(50),
quantity INT,
price_per_unit DECIMAL(10,2),
total_amount DECIMAL(10,2)
Data Flow - Agrégation des ventes
Source : Table ventes via DS_Ventes_SQL_v2

Select : Colonnes date, product_category, quantity, total_amount

Derived Column : Crée annee = year(date) et mois = month(date)

Aggregate : Group by annee, mois, product_category avec:

total_ventes = count()

ca_total = sum(total_amount)

prix_moyen = avg(total_amount / quantity)

Sink : Écriture dans la table ventes_agregees

sql
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
Automatisation
Trigger_Daily_1h : Exécution automatique du pipeline d'orchestration tous les jours à 1h00 (fuseau Eastern Time)

Captures d'écran
Toutes les captures sont disponibles dans le dossier docs/ :

blob-container-factures-pdf.png

sas-token-generation(facture-001).png

cosmos-arborescence.png

cosmos-query-result.png

cosmos-query-stats.png

linked-service.png

linked-service-blob-config.png

linked-service-sql-config.png

dataflow-aggregation-ventes.png

pipeline_orchestration_dependencies_success.png

pipeline-monitor-run.png

ADF-Pipeline-trigger.png

pipeline-trigger-daily-1h.png

query-result-pipeline.png

synapse_serverless_query_result.png

Concepts DP-900 couverts
Données relationnelles : Azure SQL Database, tables, vues, IDENTITY, SEQUENCE

Données non-relationnelles : Azure Blob Storage (SAS), Azure Cosmos DB (JSON)

ETL & Intégration : Azure Data Factory (pipelines, data flows, triggers)

Sécurité : Accès privé, SAS tokens, pare-feu SQL

Bonnes pratiques : Séparation stockage/présentation, agrégation, automatisation