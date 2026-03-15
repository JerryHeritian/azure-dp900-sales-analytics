# Concepts DP-900 couverts par le projet

Ce document détaille comment chaque domaine de l'examen Microsoft Azure Data Fundamentals (DP-900) a été mis en pratique dans le projet.

---

## 1. Concepts de base des données

| Concept | Application dans le projet |
|---------|---------------------------|
| **Données structurées** | Fichiers CSV importés dans Azure SQL Database avec schéma fixe (tables, colonnes, types) |
| **Données semi-structurées** | Documents JSON dans Cosmos DB avec structures variables (ex: certains produits ont `couleur`, d'autres `caracteristiques`) |
| **Données non-structurées** | Fichiers PDF stockés dans Azure Blob Storage (factures) |
| **OLTP vs OLAP** | SQL Database pour les transactions (ventes individuelles) vs Synapse pour l'analytique (agrégations) |
| **Batch vs streaming** | Pipeline ETL quotidien (batch) avec Azure Data Factory et trigger planifié |
| **Types de données** | Utilisation de INT, VARCHAR, DATE, DECIMAL dans SQL et JSON |

---

## 2. Données relationnelles sur Azure

| Concept | Application dans le projet |
|---------|---------------------------|
| **Azure SQL Database** | Création et configuration avec offre gratuite, mode serverless, auto-pause |
| **Tables et schémas** | Création de la table `ventes` avec clé primaire, contraintes NOT NULL, types adaptés |
| **Clés primaires** | `transaction_id` défini comme PRIMARY KEY, puis migré vers IDENTITY |
| **Index** | Index implicite sur la clé primaire, optimisation des requêtes |
| **Requêtes SQL** | SELECT, WHERE, GROUP BY, ORDER BY, fonctions d'agrégation (SUM, COUNT, AVG) |
| **Vues** | `ventes_presentation` pour formater les IDs avec préfixes (`tr_00001`) |
| **IDENTITY** | Auto-incrémentation de `transaction_id` (1, 2, 3...) |
| **SEQUENCE** | Générateur de nombres pour `customer_id` (démarre à 1000) |
| **Sécurité** | Pare-feu avec règles IP, authentification SQL |

---

## 3. Données non-relationnelles sur Azure

### 3.1 Azure Blob Storage
| Concept | Application |
|---------|-------------|
| **Compte de stockage** | `stdp900jerry` avec redondance LRS |
| **Conteneurs** | `factures-pdf` pour organiser les blobs |
| **Blobs** | Upload de fichiers CSV et PDF |
| **Accès privé** | Conteneur privé par défaut, accès via SAS tokens |
| **SAS tokens** | Génération de jetons d'accès temporaires (lecture seule, 1h) |

### 3.2 Azure Cosmos DB
| Concept | Application |
|---------|-------------|
| **Compte serverless** | `cosmos-dp900-jerry` avec offre gratuite (1000 RU/s) |
| **Base de données** | `ProduitDB` |
| **Conteneur** | `Produits` avec clé de partition `/categorie` |
| **Documents JSON** | Insertion de produits avec structures flexibles |
| **Requêtes SQL** | `SELECT * FROM Produits WHERE categorie = 'Electronique'` |
| **Clé de partition** | Optimisation des requêtes sur la catégorie |

---

## 4. Analytique moderne sur Azure

### 4.1 Azure Synapse Analytics
| Concept | Application |
|---------|-------------|
| **Workspace** | `synapse-dp900-jerry` avec pool serverless intégré |
| **Linked services** | Connexions à SQL Database et Blob Storage |
| **OPENROWSET** | Lecture directe du CSV depuis Blob Storage |
| **Vues externes** | `v_ventes_brutes` pour simplifier les requêtes récurrentes |
| **Requêtes serverless** | Analyses sans provisionnement de ressources dédiées |

### 4.2 Azure Data Factory
| Concept | Application |
|---------|-------------|
| **Pipelines** | `PL_Copy_Ventes_BLOB_to_SQL_v2` pour l'extraction |
| **Data Flow** | `DF_Aggregation_Ventes` avec transformations Select, Derived Column, Aggregate |
| **Activités** | Copy Data, Data Flow, Execute Pipeline |
| **Dépendances** | Enchaînement conditionnel ("ne lancer le Data Flow que si la copie réussit") |
| **Triggers** | `Trigger_Daily_1h` pour exécution automatique quotidienne |
| **Integration runtime** | Azure IR pour l'exécution dans le cloud |

### 4.3 Power BI
| Concept | Application |
|---------|-------------|
| **Connexion** | DirectQuery vers Synapse serverless |
| **Modélisation** | Relations entre tables, mesures calculées |
| **Visualisations** | Graphiques à barres, courbes, camemberts, cartes KPI |
| **Slicers** | Filtres interactifs par catégorie, genre, date |
| **Rapports** | Deux onglets : "Analyse ventes" et "Analyse avancée" |
| **Dashboard** | Publication sur le service Power BI (optionnel) |

---

## 5. Sécurité et bonnes pratiques

| Concept | Application |
|---------|-------------|
| **Accès privé** | Conteneurs Blob privés par défaut |
| **SAS tokens** | Accès temporaire sans exposer les clés |
| **Pare-feu SQL** | Règles IP pour autoriser les connexions |
| **Authentification** | SQL authentication et Microsoft Entra ID |
| **Versioning** | GitHub avec tous les scripts SQL et la documentation |
| **Documentation** | README détaillé, schéma d'architecture, captures d'écran |
| **Optimisation des coûts** | Offres gratuites, suppression des ressources après projet |

---

## ✅ Résumé des services Azure utilisés

| Service | Objectif | Offre utilisée |
|---------|----------|----------------|
| **Azure SQL Database** | Base relationnelle pour les ventes | Offre gratuite (100 000 vCore secondes/mois) |
| **Azure Blob Storage** | Stockage des fichiers sources et PDF | 5 Go gratuits (12 mois) |
| **Azure Cosmos DB** | Catalogue produits NoSQL | 1000 RU/s gratuits à vie |
| **Azure Data Factory** | Orchestration ETL | Mode serverless, 5 activités gratuites/mois |
| **Azure Synapse Analytics** | Analytique serverless | Paiement à la requête (négligeable) |
| **Power BI** | Visualisation | Desktop gratuit + Service gratuit |