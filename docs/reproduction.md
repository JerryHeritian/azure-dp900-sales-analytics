# Guide de reproduction – Projet Azure DP-900

Ce guide détaille les étapes pour reproduire intégralement le projet d'analyse de ventes sur Azure, depuis la création des ressources jusqu'à la visualisation Power BI.

---

# 📋 Prérequis

* Compte Azure avec un abonnement actif
  https://azure.microsoft.com/fr-ca/free/

* Power BI Desktop (gratuit)
  https://powerbi.microsoft.com/fr-fr/desktop/

* Git pour le versionnement
  https://git-scm.com/

* Navigateur web récent (Edge, Chrome, Firefox)

* Python *(optionnel pour dfvue et analyse exploratoire)*

---

# 🚀 Étape 1 : Cloner le dépôt et préparer l'environnement

```bash
# Cloner le dépôt GitHub
git clone https://github.com/JerryHeritian/azure-dp900-sales-analytics.git

cd azure-dp900-sales-analytics

# (Optionnel) Créer un environnement virtuel Python
python -m venv venv

# Activation
source venv/bin/activate     # Mac / Linux
# .\venv\Scripts\activate    # Windows

# Installer les dépendances optionnelles
pip install dfvue pandas
```

---

# 🏗️ Étape 2 : Créer les ressources Azure

## 2.1 Groupe de ressources

Nom :

```
rg-dp900-projet
```

Région :

```
Canada Central
```

---

# 2.2 Azure Blob Storage

Compte de stockage :

```
stdp900jerry
```

*(doit être globalement unique)*

Conteneur :

```
factures-pdf
```

Fichiers à uploader :

```
data/raw/Retail_Sales_clean.csv
data/raw/factures/facture-001.pdf
data/raw/factures/facture-002.pdf
data/raw/factures/facture-003.pdf
```

---

# 2.3 Azure SQL Database

Serveur SQL :

```
server-dp900-jerry.database.windows.net
```

Base de données :

```
db_sales_analytics
```

Configuration :

* Activer l'offre gratuite **Apply free offer**
* Utilisateur : `Jerry_dp900`
* Ajouter votre **IP client** dans le pare-feu
* Autoriser **les services Azure**

---

# 2.4 Exécuter les scripts SQL

Dans **Query Editor du portail Azure**, exécuter dans l'ordre :

```sql
-- 1. Création de la table
sql/01_create_tables.sql

-- 2. Insertion des données
sql/02_insert_data.sql

-- 3. Requêtes analytiques
sql/03_queries.sql

-- 4. Migration finale
sql/04_migration_finale.sql
```

---

# 2.5 Azure Cosmos DB

Compte Cosmos DB :

```
cosmos-dp900-jerry
```

Mode :

```
Serverless
```

Configuration :

* Offre gratuite **1000 RU/s à vie**
* Base de données : `ProduitDB`
* Conteneur : `Produits`
* Clé de partition :

```
/categorie
```

Importer les documents :

```
sql/produits.json
```

---

# 2.6 Azure Data Factory

Nom :

```
adf-dp900-jerry
```

Version :

```
V2
```

---

## Linked Services

* `AzureBlobStorage_LS`
* `AzureSQLDatabase_LS`

---

## Datasets

**DS_Ventes_BLOB_v2**

Source :

```
factures-pdf/Retail_Sales_clean.csv
```

**DS_Ventes_SQL_v2**

Table :

```
[dbo].[ventes]
```

---

## Pipeline : Copy Data

Pipeline :

```
PL_Copy_Ventes_BLOB_to_SQL_v2
```

Mapping colonnes :

```
Date
Gender
Age
ProductCategory
Quantity
PricePerUnit
TotalAmount
```

---

## Data Flow : Agrégation

Data Flow :

```
DF_Aggregation_Ventes
```

Transformation :

**Select**

```
date
product_category
quantity
total_amount
```

**Derived Column**

```
annee = year(date)
mois = month(date)
```

**Aggregate**

Group By :

```
annee
mois
product_category
```

Mesures :

```
total_ventes = count()
ca_total = sum(total_amount)
prix_moyen = avg(total_amount / quantity)
```

Sink :

```
DS_Ventes_Aggregated
table ventes_agregees
```

---

## Pipeline orchestration

Pipeline :

```
PL_Orchestration_Complete
```

Étapes :

1️⃣ Executer_Copie_Ventes
2️⃣ Executer_DataFlow_Aggregation

Condition :

```
activité 2 uniquement si activité 1 réussit
```

Trigger :

```
Trigger_Daily_1h
```

Exécution :

```
Tous les jours à 1h
```

---

# 2.7 Azure Synapse Analytics

Workspace :

```
synapse-dp900-jerry
```

Linked services :

```
linked_sql_ventes
linked_blob_factures
```

---

## Création de la vue externe

```sql
USE AnalyticsDB;
GO

CREATE VIEW v_ventes_brutes AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stdp900jerry.blob.core.windows.net/factures-pdf/Retail_Sales_clean.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
)
WITH (
    Date DATE,
    Gender VARCHAR(10),
    Age INT,
    ProductCategory VARCHAR(50),
    Quantity INT,
    PricePerUnit DECIMAL(10,2),
    TotalAmount DECIMAL(10,2)
) AS [result];
GO
```

Test :

```sql
SELECT TOP 10 * FROM v_ventes_brutes;
```

---

# 📊 Étape 3 : Visualisation avec Power BI

## 3.1 Installer

Installer **Power BI Desktop**.

---

## 3.2 Connexion à Synapse

Source :

```
Azure Synapse Analytics SQL
```

Serveur :

```
synapse-dp900-jerry-ondemand.sql.azuresynapse.net
```

Base :

```
AnalyticsDB
```

Mode :

```
DirectQuery
```

Authentification :

```
Compte Microsoft Azure
```

Table :

```
v_ventes_brutes
```

---

## 3.3 Rapports Power BI

### Analyse ventes

Graphiques :

* CA par catégorie → **bar chart**
* Répartition par genre → **pie chart**
* Âge moyen par catégorie → **bar chart**

---

### Analyse avancée

KPI :

```
TotalAmount
Quantity
Age
```

Graphiques :

```
ventes mensuelles
```

Slicers :

```
ProductCategory
Gender
Date
```

---

## 3.4 Publier

Options :

* Publier dans **Power BI Service**
* Export **PDF**
* Sauvegarder `.pbix`

Dossier :

```
powerbi/
```

---

# Étape 4 : Nettoyage des ressources

Pour éviter les coûts Azure :

### Via portail Azure

1. Aller dans **Groupes de ressources**
2. Sélectionner :

```
rg-dp900-projet
```

3. Cliquer :

```
Supprimer
```

---

### Via CLI

```bash
az group delete --name rg-dp900-projet --yes --no-wait
```

---

# 📸 Captures d'écran

Disponibles dans :

```
docs/images/
```

---

## Azure Blob Storage

* blob-container-factures-pdf.png
* sas-token-generation.png
* sas-access-success.png

---

## Azure Cosmos DB

* cosmos-arborescence.png
* cosmos-query-result.png
* cosmos-query-stats.png

---

## Azure Data Factory

* linked-service.png
* dataflow-aggregation-ventes.png
* pipeline_orchestration_success.png
* pipeline-monitor-run.png
* pipeline-trigger-daily-1h.png
* query-result-pipeline.png

---

## Azure Synapse

* synapse_serverless_query_result.png
* synapse_vue_ventes_par_categorie.png

---

## Power BI

* powerbi_chart_category.png
* powerbi_chart_gender.png
* powerbi_monthly_sales.png
* powerbi_kpi_cards.png
* powerbi_slicers.png
* powerbi_dashboard_complet.png

---

# Notes importantes

**Noms uniques**

Les comptes de stockage et serveurs SQL doivent être globalement uniques.

**Offres gratuites**

Toujours activer :

* SQL Database free offer
* Cosmos DB free tier

**Pare-feu SQL**

Ajouter :

* votre IP client
* les services Azure

**Data Factory**

Toujours tester en **Debug** avant publication.

**Coûts**

Supprimer les ressources après le projet.

---

# Support

Si vous rencontrez des difficultés :

* consulter la documentation Azure
* ouvrir une issue GitHub
* contacter l'auteur via GitHub
