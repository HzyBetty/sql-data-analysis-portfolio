-- ============================================================
-- Key SQL techniques:

-- Using Common Table Expressions (CTEs) to structure complex queries
-- UNION vs. UNION ALL to stack datasets with/without removing duplicates
-- Stacking datasets across years while maintaining column consistency
-- Window functions (RANK(), NTILE()) for ranking, percentiles, and quartiles
-- CASE WHEN THEN statements for conditional categorization
-- Creating and managing VIEWs for recurring or intermediate queries
-- Calculating firm-specific metrics (FSP) relative to industry averages
-- Using PARTITION BY with window functions to perform per-group computations
-- Longitudinal and percentile-based analysis of firm performance over time
-- Identifying concentration of sales among top-performing firms
-- ============================================================

--Common Table Expressions (CTEs)
--This is an example of a CTE
--Whether you run one or multiple CTEs
--they need to be run/paired with a main query after that
--If you have multiple CTEs, separate each one with a comma
--except for the last one
--The first CTE needs a "WITH" and the rest do not

WITH example20_22 AS (
	SELECT
		gvkey,
		fyear,
		conm,
		ni
	FROM Fundamentals_Annual
	WHERE fyear >= 2020 AND fyear <= 2022
	),
	
example22_24 AS (
	SELECT
		gvkey,
		fyear,
		at,
		sale
	FROM Fundamentals_Annual
	WHERE fyear >= 2022 AND fyear <= 2024
	)
	
SELECT *
FROM example20_22
INNER JOIN example22_24
USING (gvkey, fyear);

--This will result in an error
SELECT *
FROM example20_22;

--UNION vs. JOIN
--UNION is useful for stacking datasets
--Not quite the same thing as a JOIN
--Every table in a UNION "must" have the "same" number of columns
--The columns should be the same data type
--The columns have to be in the same order
--Rather than comparing columns in the left and right tables, UNION stacks them.

--JOINs can create new folumns, whereas UNION is for adding rows
--JOINs will match data, whereas UNION does not match data
--JOINs can bring together data from tables with different columns, UNION cannot

--Stacking 2023 and 2024 together
--2023 data: 12,532 rows
--2024 data: 12,619 rows

SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2023
UNION
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2024
ORDER BY fyear, gvkey;

--This is what happens when you have different columns in a UNION
--sale is in the first table, emp is in the second
--Not good at all.
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2023
UNION
SELECT
	gvkey,
	fyear,
	conm,
	emp
FROM Fundamentals_Annual
WHERE fyear = 2024
ORDER BY fyear, gvkey;

--UNION ALL includes duplicates whereas UNION does not
--Here is stacking with UNION only
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2023 OR fyear = 2024
UNION
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2022 OR fyear = 2024
ORDER BY gvkey, fyear;

--Here is stacking with UNION ALL
--See how 2024 is duplicated
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2023 OR fyear = 2024
UNION ALL
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE fyear = 2022 OR fyear = 2024
ORDER BY gvkey, fyear;

--Setting up subqueries with WHERE
--This is an error
SELECT 
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE sale >= AVG(sale);

--This is also an error. How frustrating?
SELECT 
	gvkey,
	fyear,
	conm,
	sale,
	AVG(sale) OVER() AS avg_sale
FROM Fundamentals_Annual
WHERE sale >= avg_sale;




--Hands-on Exercises
--Q1
--we are going to look at the North American 1990-2024 database, and keep all observations with $100 million or more 
--in sales (sale), $100 million or more in assets (at), a six-digit naicsh code (naicsh), nonmissing employment (emp),
-- and nonmissing net income (ni). Finally, we are only focused on observations headquartered in the United States 
--(loc = 'USA').
--As you found out before, to make industry comparisons meaningful, we only keep observations in industries with 
--at least three firms in that six-digit naicsh industry in that year.
--And now, for the rest of the question: You will now calculate firm-specific profits (fsp) for each observation. 
--FSP is defined as the firm's return on assets (ni/at) minus the average return on assets for that industry 
--(calculated using only the observations that remain after the screening above) in that year. 
--Remember that industry is defined by the six-digit naicsh. 
--How many observations in the dataset that you just created had a firm-specific profit (FSP) of greater than 0?

DROP VIEW IF EXISTS l6q1_1;
CREATE VIEW l6q1_1 AS
SELECT 
	gvkey,
	fyear,
	sale,
	at,
	naicsh,
	emp,
	ni,
	COUNT(gvkey) OVER(PARTITION BY fyear, naicsh) AS industry_cnt
FROM Fundamentals_Annual
WHERE sale >= 100
	AND	at >= 100
	AND naicsh >= 100000 AND naicsh < 1000000
	AND emp IS NOT NULL AND ni IS NOT NULL
	AND loc = "USA"
ORDER BY fyear, naicsh;

DROP VIEW IF EXISTS l6q1_2;
CREATE VIEW l6q1_2 AS
SELECT 
	*
FROM l6q1_1
WHERE industry_cnt >= 3;

DROP VIEW IF EXISTS l6q1_3;
CREATE VIEW l6q1_3 AS
SELECT 
	*,
	ni/at AS roa,
	AVG(ni/at) OVER(PARTITION BY fyear, naicsh) AS industry_roa
FROM l6q1_2;

DROP VIEW IF EXISTS l6q1_4;
CREATE VIEW l6q1_4 AS
SELECT 
	*,
	roa - industry_roa AS fsp
FROM l6q1_3
WHERE fsp > 0;


--Q2
--How many firms outperformed their industry (as defined by a firm-specific profit of greater than 0) for ten consecutive years during the period 2015-2024?
DROP VIEW IF EXISTS l6q2_1;
CREATE VIEW l6q2_1 AS
SELECT
	* ,
	COUNT() AS outperform_cnt
FROM l6q1_4
WHERE fyear >= 2015 AND fyear <= 2024
GROUP BY gvkey
HAVING outperform_cnt=10
;

--Q3
--Now, an entirely different question. 
--Suppose you are interested in examining the concentration of sales in the largest 25% of all US-based firms (by sales) in 1990.
--So first, you retain all observations from 1990, with loc = 'USA' and where sales (sale) is not equal to NULL.
--What fraction of sales of all US-based firms in 1990 were concentrated in this leading group in 1990? 
--Write your answer as a percentage, round to the nearest tenth of a percent.
DROP VIEW IF EXISTS l6q3_1;
CREATE VIEW l6q3_1 AS
SELECT
	gvkey,
	fyear,
	sale,
	NTILE(4) OVER(PARTITION BY fyear ORDER BY sale) AS quartile,  --Higher decile is better
	SUM(sale) OVER(PARTITION BY fyear) AS sale_sum
FROM Fundamentals_Annual
WHERE loc = 'USA'
	AND sale IS NOT NULL
	AND fyear = 1990
ORDER BY fyear DESC,     
		 sale DESC,
		 gvkey;

DROP VIEW IF EXISTS l6q3_2;
CREATE VIEW l6q3_2 AS
SELECT
	*,
	SUM(sale) OVER(PARTITION BY quartile) AS quartile_sum
FROM l6q3_1
ORDER BY quartile_sum DESC;

DROP VIEW IF EXISTS l6q3_3;
CREATE VIEW l6q3_3 AS
SELECT
	quartile_sum/sale_sum*100 AS quartile_pct
FROM l6q3_2
WHERE quartile = 4;


--Q4
--Now, instead of 1990, you examine the same metric for 2024. What fraction of sales of all US-based firms in 2024 were concentrated in the top 25% of firms 
--(by sales) in 2024? Like the previous question, make sure you only include observations where sales is not equal to NULL. Write your answer as a percentage, 
--round to the nearest tenth of a percent.
DROP VIEW IF EXISTS l6q4_1;
CREATE VIEW l6q4_1 AS
SELECT
	gvkey,
	fyear,
	sale,
	NTILE(4) OVER(PARTITION BY fyear ORDER BY sale) AS quartile,  --Higher decile is better
	SUM(sale) OVER(PARTITION BY fyear) AS sale_sum
FROM Fundamentals_Annual
WHERE loc = 'USA'
	AND sale IS NOT NULL
	AND fyear = 2024
ORDER BY fyear DESC,     
		 sale DESC,
		 gvkey;

DROP VIEW IF EXISTS l6q4_2;
CREATE VIEW l6q4_2 AS
SELECT
	*,
	SUM(sale) OVER(PARTITION BY quartile) AS quartile_sum
FROM l6q4_1
ORDER BY quartile_sum DESC;

DROP VIEW IF EXISTS l6q4_3;
CREATE VIEW l6q4_3 AS
SELECT
	quartile_sum/sale_sum*100 AS quartile_pct
FROM l6q4_2
WHERE quartile = 4;


--Q5
--Now, you want to examine how much the leaders are pulling away from the rest of the pack. 
--Take all US-based nonfinancial firms in 2024 with at least $100 million in assets, with non-missing net income values. 
--Examine ROA (net income divided by assets). What was the average ROA for the most profitable quartile of firms (by ROA)? 
--In other words, for the top 25% of firms by ROA, what was the average ROA in that group? Write your answer as a percentage, 
--round to the nearest tenth of a percent.
DROP VIEW IF EXISTS l6q5_1;
CREATE VIEW l6q5_1 AS
SELECT
	gvkey,
	fyear,
	naicsh,
	at,
	ni,
	ni/at*100 AS roa_pct,
	NTILE(4) OVER(PARTITION BY fyear ORDER BY ni/at*100) AS quartile
FROM Fundamentals_Annual
WHERE loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND at >= 100
	AND ni IS NOT NULL
	AND fyear = 2024
ORDER BY quartile DESC
;

SELECT
	AVG(roa_pct) 
FROM l6q5_1
WHERE quartile = 4; -- +13.4%


--Q6
--What was the average ROA for the least profitable bottom quartile of firms (by ROA) of that same group of firms in 2024? 
--Write your answer as a percentage, round to the nearest tenth of a percent.
SELECT
	AVG(roa_pct) 
FROM l6q5_1
WHERE quartile = 1; -- -33.3%



