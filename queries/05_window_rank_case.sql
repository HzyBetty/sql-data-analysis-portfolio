-- ============================================================
-- Key SQL techniques:

-- Filtering with IN, NOT IN, and BETWEEN for concise conditional statements
-- Advanced window functions: RANK() and NTILE() for ranking and creating percentiles/deciles
-- CASE WHEN THEN for conditional categorization of data
-- Creating and managing VIEWs for recurring queries
-- Combining GROUP BY with aggregate functions (AVG, COUNT) for descriptive statistics
-- Using window functions with PARTITION BY for per-group calculations without collapsing rows
-- Tracking firms over time and performing longitudinal analysis
-- Merging data from multiple VIEWs to answer dynamic questions (INNER JOIN)
-- Ranking firms by size or sales and analyzing economic contributions of subsets
-- ============================================================

SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
GROUP BY fyear, gvkey; -- Order doesn't matter for GROUP BY

--IN and NOT IN
--Can help you if you have a lot or ORs

--Canada, US and Mexico
SELECT
	gvkey,
	fyear,
	conm,
	loc
FROM Fundamentals_Annual
WHERE loc IN ('USA', 'CAN', 'MEX');

--Outside North America
SELECT
	gvkey,
	fyear,
	conm,
	loc
FROM Fundamentals_Annual
WHERE loc NOT IN ('USA', 'CAN', 'MEX');

--BETWEEN
SELECT
	gvkey,
	fyear,
	conm,
	loc
FROM Fundamentals_Annual
WHERE fyear BETWEEN 1990 AND 1995;

--More adventures in Window functions
--RANK() statement

SELECT
	gvkey,
	fyear,
	conm,
	sale,
	RANK() OVER(PARTITION BY fyear ORDER BY sale DESC) AS sales_rank
FROM Fundamentals_Annual
WHERE loc = 'USA'
	AND sale >= 0
ORDER BY fyear DESC,      --Reorder the result in the preferred order
		 sale DESC,
		 conm;

--NTILE()
--Creates buckets (e.g., deciles)

SELECT
	gvkey,
	fyear,
	conm,
	sale,
	NTILE(10) OVER(PARTITION BY fyear ORDER BY sale) AS decile  --Higher decile is better
FROM Fundamentals_Annual
WHERE loc = 'USA'
	AND sale >= 0
ORDER BY fyear DESC,     
		 sale DESC,
		 conm;

--CASE WHEN THEN statements
--Similar to the "IF-THEN-ELSE" in other programming languages

--Firm Sizes
DROP VIEW IF EXISTS firm_size;
CREATE VIEW firm_size AS
	SELECT
		gvkey,
		fyear,
		conm,
		sale,
		CASE
			WHEN sale >= 10000 THEN '1. Mega'
			WHEN sale >= 1000  AND sale < 10000 THEN '2. Large'
			WHEN sale >= 100  AND sale < 1000 THEN '3. Medium'
			WHEN sale >= 0  AND sale < 100 THEN '4. Small'
			ELSE '5. Negative or no data'
		END AS size
	FROM Fundamentals_Annual
	WHERE fyear = 2024 AND loc = 'USA';

--Now, we group this new size variable for descriptive statistics
SELECT
	size,
	COUNT(size) AS obs
FROM firm_size
GROUP BY size;




--Hands-on Exercises

--Q1
--Now, we are interested in a series of questions that examine the dynamism of the US economy.
--Start with firms in 1990. Divide all observations from that year into five groups. 
--Those in the largest 20% of assets, those in the next 20% of assets, all the way down to the bottom 20% of assets. 
--Now, calculate the average ROA (net income divided by assets, which is ni/at in Compustat) for each group in 1990.
--Make sure that the observations in your analysis are headquartered in the United States, and are not missing ni or at.

Start with firms in 1990. Divide all observations from that year into five groups. Those in the largest 20% of assets, those in the next 20% of assets, all the way down to the bottom 20% of assets. Now, calculate the average ROA (net income divided by assets, which is ni/at in Compustat) for each group in 1990.

Make sure that the observations in your analysis are headquartered in the United States, and are not missing ni or at.
DROP VIEW IF EXISTS firm_roa;
CREATE VIEW firm_roa AS
	SELECT
	gvkey,
	fyear,
	ni,
	at,
	ni/at * 100 AS roa,
	NTILE(5) OVER(PARTITION BY fyear ORDER BY at) AS pentile
	FROM Fundamentals_Annual
	WHERE loc = 'USA'
		AND fyear = 1990
		AND at IS NOT NULL
		AND ni IS NOT NULL;		


SELECT
	AVG(roa) as roa_avg
FROM firm_roa
GROUP BY pentile;

--Q2
--Now, redo the above analysis with the following screening procedure:
--Use observations from 1990 that are nonfinancial, US-headquartered firms 
--with at least $50 million in assets in that year, and not missing net income (ni).
DROP VIEW IF EXISTS firm_roa;
CREATE VIEW firm_roa AS
	SELECT
	gvkey,
	fyear,
	ni,
	at,
	ni/at * 100 AS roa,
	NTILE(5) OVER(PARTITION BY fyear ORDER BY at) AS pentile
	FROM Fundamentals_Annual
	WHERE loc = 'USA'
		AND fyear = 1990
		AND naicsh NOT lIKE '52%'
		AND at >= 50
		AND at IS NOT NULL
		AND ni IS NOT NULL;	

SELECT
	AVG(roa) as roa_avg
FROM firm_roa
GROUP BY pentile;

--Q3
--Now, let's start again by tracking 1990 firms over time.
--Start with all nonfinancial, US-headquartered firms from 1990. 
--Rank the firm with the highest sales as 1, all the way to the 500th largest sales as 500.
--What is the average ROA (ni/at) for this group of 500 firms in 1990?
DROP VIEW IF EXISTS firm_roa;
CREATE VIEW firm_roa AS
	SELECT
	gvkey,
	fyear,
	ni,
	at,
	sale,
	ni/at * 100 AS roa,
	costat,
	RANK() OVER(PARTITION BY fyear ORDER BY sale DESC) AS sales_rank
	FROM Fundamentals_Annual
	WHERE loc = 'USA'
		AND fyear = 1990
		AND naicsh NOT lIKE '52%'
		AND at IS NOT NULL
		AND ni IS NOT NULL;	
		
SELECT
	AVG(roa) AS roa
FROM firm_roa
WHERE sales_rank <= 500;

DROP VIEW IF EXISTS firm_500;
CREATE VIEW firm_500 AS
SELECT 
	gvkey
FROM firm_roa
WHERE sales_rank <= 500;

--Q4
--How many of 500 largest nonfinancial US-headquartered firms (by sales) 
--in the previous question from 1990 were still publicly traded in 2024?
--What was the average ROA in 2024 for that top 500 group from 1990 
--that still existed?

DROP VIEW IF EXISTS firm_y24;
CREATE VIEW firm_y24 AS
SELECT
	gvkey,
	ni/at*100 AS roa
FROM Fundamentals_Annual
WHERE fyear = 2024;

DROP VIEW IF EXISTS firm_q4_exist;
CREATE VIEW firm_q4_exist AS
SELECT
	*
FROM firm_y24
INNER JOIN firm_500
USING (gvkey);

SELECT 
	AVG(roa)
FROM firm_q4_exist;


--Q5
--You are curious about how much economic activity is generated by leading firms
--today that are relatively new.
--Let the total value of all sales from the 500 largest US-based firms in 2024 
--(based on 2024 sales) be called S.
--What percentage of S comes from firms not publicly traded in 1990?

DROP VIEW IF EXISTS view_l6q5;
CREATE VIEW view_l6q5 AS
	SELECT
		gvkey,
		fyear,
		sale,
		RANK() OVER(PARTITION BY fyear ORDER BY sale DESC) AS sales_rank,
		CASE
			WHEN gvkey IN (SELECT 
								gvkey 
							FROM Fundamentals_Annual 
							WHERE fyear = 1990) THEN 'yes'
		ELSE 'no'
		END AS public_1990
	FROM Fundamentals_Annual
	WHERE fyear = 2024 
	AND loc = 'USA';

SELECT
	SUM(sale)
FROM view_l6q5
WHERE sales_rank <= 500; -- 20048240.442

SELECT
	SUM(sale)
FROM view_l6q5
WHERE sales_rank <= 500
AND public_1990 = 'no'; -- 7266350.948

--Q6
--Now you want to know which firms have staying power.
--Suppose you rank the 500 largest US-based firms in 1990
--in descending order of sales from highest to lowest. 
--You do this again, year after year, until 2024. 
--How many firms would make the list every single year?
DROP VIEW IF EXISTS view_l6q6;
CREATE VIEW view_l6q6 AS
	SELECT
		gvkey,
		fyear,
		sale,
		RANK() OVER(PARTITION BY fyear ORDER BY sale DESC) AS sales_rank
	FROM Fundamentals_Annual 
	WHERE loc = 'USA';

SELECT 
	gvkey,
	COUNT(fyear) AS year_cnt
FROM view_l6q6
WHERE sales_rank <= 500
GROUP BY gvkey
HAVING year_cnt = 35;