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

## Azure Synapse - Requêtes serverless

### Première requête : lecture du CSV dans Blob Storage
```sql
SELECT TOP 100 *
FROM OPENROWSET(
    BULK 'https://stdp900jerry.blob.core.windows.net/factures-pdf/Retail_Sales_clean.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0'
) AS [result]



Captures d'écran
Toutes les captures sont disponibles dans le dossier docs/ :

Azure Synapse Analytics
synapse_serverless_query_result.png : Résultat de la première requête serverless – Lecture réussie du fichier CSV directement depuis Blob Storage sans import préalable.

synapse_openrowset_syntax.png : Syntaxe correcte de OPENROWSET – Exemple de requête avec mapping de colonnes et gestion de l'en-tête.

synapse_external_view.png : Création d'une vue externe – Simplification des requêtes récurrentes sur les fichiers.

Blob Storage
blob-container-factures-pdf.png : Conteneur Blob avec les fichiers PDF – Stockage des factures non structurées.

sas-token-generation(facture-001).png : Génération d'un jeton SAS – Accès temporaire sécurisé à un fichier.

Cosmos DB
cosmos-arborescence.png : Arborescence Cosmos DB – Structure base → conteneur → items.

cosmos-query-result.png : Résultat d'une requête Cosmos DB – Exemple de documents JSON.

cosmos-query-stats.png : Statistiques de requête – Affichage des Request Units (RU) consommées.

Data Factory
linked-service.png : Liste des linked services – Connexions à Blob Storage et Azure SQL.

linked-service-blob-config.png : Configuration du linked service Blob – Paramètres de connexion.

linked-service-sql-config.png : Configuration du linked service SQL – Authentification et base de données.

dataflow-aggregation-ventes.png : Data Flow d'agrégation – Transformations Select, Derived Column, Aggregate.

Pipelines et orchestration
pipeline_orchestration_dependencies_success.png : Pipeline d'orchestration réussi – Exécution avec dépendances entre activités.

pipeline-monitor-run.png : Suivi d'exécution dans Monitor – Vue des pipelines en cours et terminés.

ADF-Pipeline-trigger.png : Configuration du trigger – Paramètres du déclencheur quotidien.

pipeline-trigger-daily-1h.png : Trigger quotidien actif – Planification à 1h00.

query-result-pipeline.png : Résultat après exécution du pipeline – Vérification des données importées.

synapse_external_view.png : Création d'une vue externe – Simplification des requêtes récurrentes sur les fichiers.

synapse_vue_ventes_par_categorie.png : **Analyse des ventes par catégorie via la vue** – Requête SQL exécutée sur la vue `v_ventes_brutes` montrant le nombre de ventes, les quantités totales et le chiffre d'affaires par catégorie de produit.

powerbi_dashboard_complet.png : **Tableau de bord complet** – Visualisations des ventes par catégorie, âge moyen des clients par catégorie, répartition des ventes par genre (Homme/Femme ~51%/49%) et segment de date pour le filtrage interactif.

powerbi_onglet_avance_final.png : **Nouvel onglet "Analyse avancée"** – Vue d'ensemble avec cartes KPI (CA total, quantité totale, âge moyen), graphique des ventes mensuelles et slicers interactifs.

powerbi_monthly_sales_final.png : **Ventes mensuelles** – Graphique en courbes montrant l'évolution du chiffre d'affaires mois par mois.

powerbi_kpi_cards_final.png : **Indicateurs clés** – Cartes affichant les KPI principaux alignés en haut du dashboard.

powerbi_slicers_final.png : **Filtres interactifs** – Segments pour filtrer par catégorie de produit et par genre.