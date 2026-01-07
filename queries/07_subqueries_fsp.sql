-- ============================================================
-- Key SQL techniques:

-- Using subqueries in WHERE clauses to filter based on aggregates
-- Subqueries in SELECT clauses to calculate derived metrics per row
-- Nested subqueries for multi-level calculations (e.g., average of averages)
-- Using IN / NOT IN to filter based on a set of values from a subquery
-- Combining subqueries and window functions (RANK(), NTILE()) for rankings and quartiles
-- Creating firm-specific profit (FSP) relative to industry-year averages
-- Filtering by firm count per industry using window functions (COUNT() OVER PARTITION BY)
-- Longitudinal analysis across years (e.g., comparing 2023 and 2024 firm performance)
-- Using VIEWs to store intermediate results for complex multi-step queries
-- ============================================================

--Simple subqueries with WHERE
--Subqueries are queries nested in another QUERY
--This can be in any part of the query: (SELECT, FROM, WHERE)
--A simple subquery can be run on its own
--The subquery is evaluated first, then the other query is evaluated second.

--1. Subqueries in a WHERE
--They are useful because aggregate functions cannot be run in a WHERE

--For example, this is an error:
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE sale >= AVG(sale);

--This is also an error with a WINDOW function. How frustrating!
SELECT
	gvkey,
	fyear,
	conm,
	AVG(sale) OVER() AS avg_sale
From Fundamentals_Annual
WHERE sale >= AVG(sale);

--A subquery of WHERE to the rescue!
--How to select observations with sales greater than or equal to the dataset average.
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE sale >=
	(SELECT AVG(sale)
	FROM Fundamentals_Annual);
	

--The following examples illustrate that one has to be careful with conditional statements
--Consider what happens with conditions in the inner and outer query
--This is a query for year 2024 observations with sales greater than or equal to the dataset average
--Returns 1,649 observations
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE fyear = 2024
AND sale >= 
			(SELECT AVG(sale)
			FROM Fundamentals_Annual);
			
--Select observations with sales greater than or equal to the 2024 average
--Returns 25,546 observations
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE sale >= 
			(SELECT AVG(sale)
			FROM Fundamentals_Annual
			WHERE fyear = 2024);

--A query that returns year 2024 observations with sales greater than or equal to the 2024 average
--Returns 1,052 observations
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE fyear = 2024
AND sale >= 
			(SELECT AVG(sale)
			FROM Fundamentals_Annual
			WHERE fyear = 2024);
			
--You can also use a list or a column for WHERE subqueries
--For example, retaining observations over all years from firms that were publicly traded in 1990
--So, you'll keep firms like Apple or GE, but not Amazon
SELECT
	gvkey,
	fyear,
	conm,
	sale
From Fundamentals_Annual
WHERE gvkey IN
			(SELECT gvkey
			FROM Fundamentals_Annual
			WHERE fyear = 1990);

--Or, you can use a WHERE subquery to find all observations going back in time
--From firms publicly traded in 2024
--In this query, you'll find Amazon or Tesla
--Notice 174,201 observations
SELECT
	gvkey,
	fyear,
	conm
From Fundamentals_Annual
WHERE gvkey IN
			(SELECT gvkey
			FROM Fundamentals_Annual
			WHERE fyear = 2024)
ORDER BY gvkey,fyear DESC;

--Now, we turn to subqueries in SELECT clauses
--These subqueries return a single value as a column

--Earlier, in WINDOW functions (this is not a subquery)
SELECT 
	gvkey,
	fyear,
	conm,
	sale,
	AVG(sale) OVER() AS avg_sale
From Fundamentals_Annual
WHERE fyear = 2024;

--Here is another way to run the same query
--Now, we use a subquery and SELECT from the same table
SELECT
	gvkey,
	fyear,
	conm,
	sale,
	(SELECT 
		AVG(sale)
		FROM Fundamentals_Annual
		WHERE fyear = 2024) AS avg_sale
From Fundamentals_Annual
WHERE fyear = 2024;

--Using a subquery in SELECT to get beyond what a WINDOW function can achieve
--For example, using different WHERE statements from an inner and outer QUERY
SELECT
	gvkey,
	fyear,
	conm,
	sale,
	(SELECT 
		AVG(sale)
		FROM Fundamentals_Annual
		WHERE fyear >= 2020 AND fyear <= 2024) AS avg_sale5yr
From Fundamentals_Annual
WHERE fyear = 2024 AND
		sale >= avg_sale5yr;

-- For later - using the subquery from SELECT in a WHERE clause

--The last one is useful for aggregates of aggregate
--Suppose you want the average ROA from these 35 yearly averages

SELECT
	fyear,
	AVG(ni/at) AS roa_avg,
	COUNT(gvkey) AS obs
From Fundamentals_Annual
WHERE 
	loc = 'USA'
	AND at >= 1000
	AND emp IS NOT NULL
GROUP BY fyear;


SELECT 
	AVG(roa_avg) AS avg_avg_ROA
FROM
	( SELECT
		fyear,
		AVG(ni/at) AS roa_avg,
		COUNT(gvkey) AS obs
	From Fundamentals_Annual
	WHERE 
		loc = 'USA'
		AND at >= 1000
		AND emp IS NOT NULL
	GROUP BY fyear
	) AS roa_annual;



	

	
	
--Hands-on Exercises

--Q1
--You are curious about the persistence of competitive advantage, and whether that has changed over time.
--So you start with firms headquartered in the United States, with at least $100 million in assets
--and nonmissing employment, net income, sales, and 6-digit naicsh codes.
--You then create an industry-average ROA for each industry-year combination. 
--For proper industry analysis, you also drop any industry with less than 3 firms in that 6-digit industry in that year. 
--Call this industry-average ROA roa_ind. Also include fsp (firm-specifc profit) in your final output 
--(this will become handy for future questions). Recall that fsp is the firm's ROA minus the industry average ROA in that year.
--How many firm-year observations from the 1990-2024 stock market data conform to these requirements?

DROP VIEW IF EXISTS e7q1;
CREATE VIEW e7q1 AS
SELECT *, roa-roa_ind AS fsp
FROM
		(SELECT *, AVG(roa) OVER(PARTITION BY fyear, naicsh) AS roa_ind
		FROM
				(SELECT
					gvkey,
					fyear,
					conm,
					ni,
					at,
					emp,
					sale,
					naicsh,
					ni/at*100 AS roa,
					COUNT(gvkey) OVER(PARTITION BY fyear, naicsh) AS firm_cnt
				From Fundamentals_Annual
				WHERE loc = 'USA' 
				AND	at >= 100
				AND emp IS NOT NULL
				AND ni IS NOT NULL
				AND sale IS NOT NULL
				AND naicsh >= 100000 AND naicsh < 1000000)
		WHERE firm_cnt >= 3)
		;
	

--Q2
--How many *firms* that had an fsp in 2023 (based on the same screening procedures above) also had an fsp in 2024? 
--In other words, how many firms had an fsp in both years?
SELECT gvkey 
FROM e7q1 
WHERE fyear = 2024 
AND fsp IS NOT NULL
AND gvkey IN
	(SELECT gvkey
	FROM e7q1
	WHERE fyear = 2023
	AND fsp IS NOT NULL);
	 

--Q3
--How many firms from 2023 that were in the top quartile for fsp for their industry were also in the top quartile of fsp in 2024?
--Order from highest to lowest then 485, order from lowest to highest then 483
SELECT *
		FROM
				(SELECT *,
						ntile(4) OVER(PARTITION BY fyear ORDER BY fsp DESC) AS fsp_quartile_24
					FROM e7q1
					WHERE fyear = 2024)
		WHERE 
		fsp_quartile_24 = 1
		AND gvkey IN
		(SELECT gvkey 
		 FROM
				(SELECT *,
						ntile(4) OVER(PARTITION BY fyear ORDER BY fsp DESC) AS fsp_quartile_23
					FROM e7q1
					WHERE fyear = 2023)
		 WHERE 
		 fsp_quartile_23 = 1);
