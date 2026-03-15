# Guide de reproduction – Projet Azure DP-900

Ce guide détaille les étapes pour reproduire intégralement le projet d'analyse de ventes sur Azure, depuis la création des ressources jusqu'à la visualisation Power BI.

---

## 📋 Prérequis

- Compte Azure avec un abonnement actif ([crédit gratuit de 200$](https://azure.microsoft.com/fr-ca/free/))
- Power BI Desktop ([téléchargement gratuit](https://powerbi.microsoft.com/fr-fr/desktop/))
- Git pour le versionnement ([télécharger Git](https://git-scm.com/))
- Navigateur web récent (Edge, Chrome, Firefox)
- Python (optionnel, pour dfvue et l'analyse exploratoire)

---

## 🚀 Étape 1 : Cloner le dépôt et préparer l'environnement

```bash
# Cloner le dépôt GitHub
git clone https://github.com/JerryHeritian/azure-dp900-sales-analytics.git
cd azure-dp900-sales-analytics

# (Optionnel) Créer un environnement virtuel Python
python -m venv venv
source venv/bin/activate  # Sur Mac/Linux
# .\venv\Scripts\activate  # Sur Windows

# Installer les dépendances optionnelles (dfvue pour explorer les CSV)
pip install dfvue pandas
🏗️ Étape 2 : Créer les ressources Azure
2.1 Groupe de ressources
Nom : rg-dp900-projet

Région : Canada Central (ou proche de vous)

2.2 Azure Blob Storage
Compte de stockage : stdp900jerry (nom globalement unique)

Conteneur : factures-pdf

Fichiers à uploader :

Source de données : data/raw/Retail_Sales_clean.csv

Factures : data/raw/factures/facture-001.pdf, facture-002.pdf, facture-003.pdf

2.3 Azure SQL Database
Serveur SQL : server-dp900-jerry.database.windows.net

Base de données : db_sales_analytics

Activer l'offre gratuite (bannière "Apply free offer")

Authentification : utilisateur Jerry_dp900 (retenir le mot de passe)

Pare-feu : ajouter votre IP client + autoriser les services Azure

2.4 Exécuter les scripts SQL
Dans l'éditeur de requêtes du portail Azure, exécuter dans l'ordre :

sql
-- 1. Création de la table
sql/01_create_tables.sql

-- 2. Insertion des données exemple
sql/02_insert_data.sql

-- 3. Requêtes d'analyse
sql/03_queries.sql

-- 4. Migration finale (IDENTITY, SEQUENCE, vues)
sql/04_migration_finale.sql
2.5 Azure Cosmos DB
Compte Cosmos DB : cosmos-dp900-jerry

Mode : Serverless

Activer l'offre gratuite (1000 RU/s à vie)

Base de données : ProduitDB

Conteneur : Produits avec clé de partition /categorie

Insérer les documents depuis sql/produits.json (ou manuellement via Data Explorer)

2.6 Azure Data Factory
Data Factory : adf-dp900-jerry (version V2)

Linked services :

AzureBlobStorage_LS : connexion au compte stdp900jerry

AzureSQLDatabase_LS : connexion à db_sales_analytics

Datasets :

DS_Ventes_BLOB_v2 : source CSV (chemin : factures-pdf/Retail_Sales_clean.csv)

DS_Ventes_SQL_v2 : sink table [dbo].[ventes]

Pipeline extraction PL_Copy_Ventes_BLOB_to_SQL_v2 :

Activité Copy Data avec mapping 7 colonnes (Date, Gender, Age, ProductCategory, Quantity, PricePerUnit, TotalAmount)

Data Flow DF_Aggregation_Ventes :

Source : DS_Ventes_SQL_v2

Select : garder date, product_category, quantity, total_amount

Derived Column : créer annee = year(date), mois = month(date)

Aggregate : group by annee, mois, product_category avec :

total_ventes = count()

ca_total = sum(total_amount)

prix_moyen = avg(total_amount / quantity)

Sink : DS_Ventes_Aggregated (table ventes_agregees)

Pipeline orchestration PL_Orchestration_Complete :

Activité 1 : Executer_Copie_Ventes (appelle PL_Copy_Ventes_BLOB_to_SQL_v2)

Activité 2 : Executer_DataFlow_Aggregation (appelle DF_Aggregation_Ventes)

Dépendance : activité 2 ne se lance que si activité 1 réussit

Trigger Trigger_Daily_1h : exécution automatique tous les jours à 1h00

2.7 Azure Synapse Analytics
Workspace Synapse : synapse-dp900-jerry

Linked services :

linked_sql_ventes : connexion à db_sales_analytics

linked_blob_factures : connexion à stdp900jerry

Créer la vue externe (dans l'éditeur SQL) :

sql
-- Sélectionner la base de données
USE AnalyticsDB;
GO

-- Créer la vue
CREATE VIEW v_ventes_brutes AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stdp900jerry.blob.core.windows.net/factures-pdf/Retail_Sales_clean.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    Date DATE,
    Gender VARCHAR(10),
    Age INT,
    ProductCategory VARCHAR(50),
    Quantity INT,
    PricePerUnit DECIMAL(10,2),
    TotalAmount DECIMAL(10,2)
) AS [result];
GO

-- Tester la vue
SELECT TOP 10 * FROM v_ventes_brutes;
GO
📊 Étape 3 : Visualisation avec Power BI
3.1 Installer et configurer
Télécharger et installer Power BI Desktop

Lancer l'application

3.2 Connexion à Synapse
Obtenir des données → Azure → Azure Synapse Analytics SQL

Serveur : synapse-dp900-jerry-ondemand.sql.azuresynapse.net

Base de données : AnalyticsDB

Mode : DirectQuery (recommandé)

Authentification : Compte Microsoft (celui lié à Azure)

Sélectionner la vue v_ventes_brutes

3.3 Créer les rapports
Onglet "Analyse ventes"

Barres CA par catégorie : Axe ProductCategory, Valeurs TotalAmount

Camembert par genre : Légende Gender, Valeurs TotalAmount

Barres âge moyen : Axe ProductCategory, Valeurs Age (moyenne)

Onglet "Analyse avancée"

Cartes KPI : TotalAmount (CA total), Quantity (quantité totale), Age (moyenne)

Courbes ventes mensuelles : Axe Date (par mois), Valeurs TotalAmount

Slicers : ProductCategory, Gender, Date

3.4 Publier et partager
Publier sur le service Power BI (optionnel, nécessite un compte professionnel ou scolaire)

Exporter en PDF : Fichier → Exporter → PDF

Sauvegarder le fichier source .pbix dans le dossier powerbi/

🧹 Étape 4 : Nettoyage des ressources (optionnel)
Pour éviter les coûts inutiles après le projet :

bash
# Via le portail Azure
# 1. Aller dans "Groupes de ressources"
# 2. Sélectionner "rg-dp900-projet"
# 3. Cliquer sur "Supprimer le groupe de ressources"
# 4. Confirmer en tapant le nom du groupe

# Ou via Azure CLI
az group delete --name rg-dp900-projet --yes --no-wait
📸 Captures d'écran du projet
Toutes les captures sont disponibles dans le dossier docs/images/ :

Azure Blob Storage

blob-container-factures-pdf.png : Conteneur factures-pdf avec les fichiers PDF et CSV

sas-token-generation.png : Génération d'un jeton SAS pour accès temporaire

sas-access-success.png : Accès réussi à un fichier avec jeton SAS

Azure Cosmos DB

cosmos-arborescence.png : Arborescence Cosmos DB (base → conteneur → items)

cosmos-query-result.png : Résultat d'une requête sur documents JSON

cosmos-query-stats.png : Statistiques de requête (Request Units consommées)

Azure Data Factory

linked-service.png : Liste des linked services configurés

dataflow-aggregation-ventes.png : Data Flow d'agrégation (Select, Derived Column, Aggregate)

pipeline_orchestration_success.png : Pipeline d'orchestration réussi avec dépendances

pipeline-monitor-run.png : Suivi des exécutions dans Monitor

pipeline-trigger-daily-1h.png : Configuration du trigger quotidien

query-result-pipeline.png : Résultat après exécution du pipeline

Azure Synapse Analytics

synapse_serverless_query_result.png : Requête serverless sur CSV dans Blob Storage

synapse_vue_ventes_par_categorie.png : Analyse via la vue v_ventes_brutes

Power BI

powerbi_chart_category.png : Graphique des ventes par catégorie

powerbi_chart_gender.png : Répartition des ventes par genre

powerbi_monthly_sales.png : Évolution mensuelle des ventes

powerbi_kpi_cards.png : Cartes KPI (CA total, quantité, âge moyen)

powerbi_slicers.png : Filtres interactifs (catégorie, genre, date)

powerbi_dashboard_complet.png : Tableau de bord final complet

⚠️ Notes importantes
Noms uniques : Les noms des comptes de stockage et serveurs SQL doivent être globalement uniques (ajoutez un suffixe personnel si nécessaire)

Offres gratuites : Activez systématiquement les offres gratuites lors de la création des ressources (SQL Database, Cosmos DB)

Pare-feu SQL : N'oubliez pas d'ajouter votre IP client et d'autoriser les services Azure

Debug : Utilisez le mode Debug dans Data Factory avant de publier les pipelines

Coûts : Pensez à supprimer les ressources après le projet pour éviter des frais inutiles

🆘 Support
Si vous rencontrez des difficultés :

Consultez la documentation Microsoft Azure

Ouvrez une issue sur le dépôt GitHub

Contactez l'auteur via GitHub