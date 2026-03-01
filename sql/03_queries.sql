-- 1. Chiffre d'affaire totale
SELECT sum(price_per_unit) AS chiffre_affaire_totale
FROM [dbo].[ventes];

-- 2. Chiffre d'affaires par catégorie
SELECT product_category AS Category,
sum(total_amount) as Chiffre_affaire
FROM [dbo].[ventes]
GROUP BY product_category
ORDER BY Chiffre_affaire DESC;

-- 3. Top 10 des transactions les plus élevées
SELECT TOP 10 transaction_id, date, customer_id, product_category, total_amount
FROM [dbo].[ventes]
ORDER BY total_amount DESC;


-- 4. Nombre de transactions par genre
SELECT count(transaction_id) as nb_transaction, gender as genre
FROM [dbo].[ventes]
GROUP BY gender;

-- 5. Âge moyen des clients par catégorie
SELECT avg(age) as age_moyen, product_category as categorie
FROM [dbo].[ventes]
GROUP BY product_category;

-- 6. Jour avec le plus gros chiffre d'affaires
SELECT TOP 1 date, SUM(total_amount) as chiffre_affaire_journalier
FROM [dbo].[ventes]
GROUP BY date
ORDER BY chiffre_affaire_journalier DESC;

-- 7. Quantité totale vendue par catégorie
SELECT product_category, sum(quantity) as quantite_totale
FROM [dbo].[ventes]
GROUP BY product_category
ORDER BY quantite_totale DESC;