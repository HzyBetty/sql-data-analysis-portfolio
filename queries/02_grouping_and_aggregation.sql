-- ============================================================
-- Key SQL techniques:

-- ORDER BY for sorting results (ascending/descending)
-- DISTINCT to identify unique values
-- COUNT() to compute number of observations
-- Logical operators (AND, OR) and importance of brackets for correct logic
-- Filtering by numeric ranges and categorical values
-- Understanding and using industry codes (NAICS)
-- GROUP BY to aggregate data by one or more fields
-- Aggregate functions with GROUP BY (AVG, COUNT, MAX, MIN)
-- HAVING to filter aggregated results
-- Combining filters, grouping, and aggregation for analytical exercises
-- ============================================================

-- Using the ORDER BY statement
-- Can be ascending or descending

SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE loc = 'USA' AND fyear = 2024
ORDER BY sale DESC
LIMIT 500;

-- Change from 1990
-- The economy has changed qiute a bit, hasn't it?

SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE loc = 'USA' AND fyear = 1990
ORDER BY sale DESC
LIMIT 500;

-- The DISTINCT statement
-- How many different gvkeys are there?
SELECT DISTINCT gvkey
FROM Fundamentals_Annual;

-- How many different countries are there?
SELECT DISTINCT loc
FROM Fundamentals_Annual;

-- How many different gvkeys, fyear combinations are there?
SELECT DISTINCT gvkey, fyear
FROM Fundamentals_Annual;

-- The COUNT() statement
-- How many observations are there?
SELECT COUNT(*)
FROM Fundamentals_Annual;

-- How many non-NULL observations of sale are there?
SELECT COUNT(sale)
FROM Fundamentals_Annual;

-- How many DISTINCT gvkeys of sale are there?
SELECT COUNT(DISTINCT gvkey)
FROM Fundamentals_Annual;

-- Some AND plus OR together
-- Don't do queries like this
SELECT
	gvkey,
	fyear,
	conm,
	tic,
	loc
FROM Fundamentals_Annual
WHERE loc='CAN' OR fyear=2024 AND loc='USA';

-- Always, always use brackets
SELECT
	gvkey,
	fyear,
	conm,
	tic,
	loc
FROM Fundamentals_Annual
WHERE loc='CAN' OR (fyear=2024 AND loc='USA');

-- An appreciation of NAICS codes
-- NAICS codes are the firm's industry (and primary industry if in more than one industry)
-- NAICS 99 is a firm so diversified it can't be classified

-- Firms classified at only two digits
SELECT
	gvkey,
	fyear,
	conm,
	naicsh
FROM Fundamentals_Annual
WHERE naicsh <= 100;

-- Six digits of naicsh
SELECT
	gvkey,
	fyear,
	conm,
	naicsh
FROM Fundamentals_Annual
WHERE naicsh >= 100000 AND naicsh <= 999999;

-- GROUP BY
-- Let's you group by any field(s) you like
-- Let's start by grouping by one variable
-- DON'T USE GROUP BY WITHOUT PAIRING WITH AN AGGREGATE FUNCTION (SUMMARY STATISTIC)

-- BAD
SELECT 
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
GROUP BY gvkey;

-- A better QUERY
-- As a general rule, you want to SELECT the variable you are grouping by
-- All other variables should be summary statistics
-- Ignores the NULL automatically
SELECT
	gvkey,
	AVG(sale) as avg_sales
FROM Fundamentals_Annual
GROUP BY gvkey;

SELECT
	gvkey,
	AVG(sale) as avg_sales
FROM Fundamentals_Annual;

-- An example of average sales for US firms plus the number of observations per year
-- We are grouping by fyear. All other variables will be summary statistics

SELECT
	fyear,
	AVG(sale) as avg_sales,
	COUNT(sale) AS obs
FROM Fundamentals_Annual
WHERE loc='USA'
GROUP BY fyear;

-- An example with HAVING
-- Note that HAVING comes after GROUP BY
-- Use the WHERE clause for any "raw" variable from Fundamentals_Annual you filter on.
-- A newly created variable such as obs is filtered with the HAVING clause
SELECT
	fyear,
	AVG(sale) AS avg_sales,
	COUNT(sale) AS obs
FROM Fundamentals_Annual
WHERE loc='USA'
GROUP BY fyear
HAVING obs>=8000;




-- Hands-on Exercises
-- Q1
--Which fiscal year had the highest average sales per employee 
--for firms headquartered in the United States?

SELECT  fyear, AVG(sale/emp) 
FROM Fundamentals_Annual
WHERE loc = 'USA' 
GROUP by fyear
ORDER by AVG(sale/emp) DESC;


-- Q2
--You now want a dataset in which you keep firms as long as 
--they reached $100 million in assets in any year in the dataset.
--To elaborate, let's consider the following hypothetical case:
--Suppose there are 6 observations for company ABC. 
--If at least one of these 6 observations has assets of at least $100 million, 
--you must NOT drop ANY of the observations for firm ABC.
--How many firms (i.e., gvkeys) are left after this screening procedure?



SELECT
	gvkey,
	MAX(at) AS max_at
FROM Fundamentals_Annual
GROUP BY gvkey
HAVING max_at >= 100;

-- Q3
--Now, start by keeping observations if they have at least $100 million in assets, 
--$100 million in sales, nonmissing values of employment, 
--and are headquartered in the United States.
--In this sample of American firms, 
--how many years did average employment per firm exceed 14,000?

SELECT
	gvkey,
	at,
	sale,
	loc,
	emp,
	fyear,
	AVG(emp) as avg_emp
FROM Fundamentals_Annual
WHERE at>=100 
AND sale>=100 
AND emp IS NOT NULL 
AND loc='USA' 
GROUP by fyear
HAVING avg_emp>14;

-- Q4
--Consider US-based firms in 2024. 
--What is the ticker for the 100th largest firm by employment?
SELECT
	fyear,
	tic,
	emp,
	loc
FROM Fundamentals_Annual
WHERE loc='USA' AND fyear=2024
ORDER BY emp DESC;

-- Q5
--How many firms are in the database for all 35 years (1990-2024)?
SELECT
	gvkey,
	COUNT(fyear) AS cnt
FROM Fundamentals_Annual
WHERE fyear<=2024 AND fyear >=1990
GROUP BY gvkey
HAVING cnt=35;

-- Q6
--Now, take American nonfinancial firms with at least $500 million in assets 
--in every year for all 35 years of the database (1990-2024). 
--What is the ticker for the firm with the highest average ROA 
--(net income divided by assets) during this time?

SELECT
				gvkey,
				tic,
				loc,
				fyear,
				naicsh,
				MIN(at) AS min_at,
				AVG(ni/at) AS roi_avg,
				COUNT(fyear) AS cnt
			FROM Fundamentals_Annual
			WHERE loc='USA' 
			AND fyear>=1990 AND fyear<=2024
			AND naicsh NOT LIKE "52%"
			GROUP BY gvkey, tic
			Having min_at>=500 AND cnt=35
			ORDER BY roi_avg DESC
			;




