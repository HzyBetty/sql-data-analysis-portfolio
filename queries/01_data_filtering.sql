-- ============================================================
-- Key SQL techniques:

-- SELECT and FROM to retrieve firm-level financial data
-- WHERE for conditional filtering (firm, year, country, industry)
-- Calculated fields for financial ratios (e.g., ROA = net income / total assets)
-- Handling data quality issues (NULL vs. zero values)
-- Aggregate functions (AVG) for summary statistics
-- Industry classification using pattern matching (LIKE / NOT LIKE)
-- Applying multiple filters for analytical subsamples (nonfinancial, size thresholds)
-- ============================================================

-- Selecting all variables from the Fundamentals_Annual table

SELECT *
FROM Fundamentals_Annual;

-- Tesla's return on assets each year
-- Return on assets is net income divided by assets
SELECT
	gvkey,
	fyear,
	tic,
	ni,
	at,
	100*ni/at AS roa_pct
FROM Fundamentals_Annual
WHERE tic = "TSLA";


-- The concept of NULL vs. zero
-- These are firms with zero sales
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE sale = 0 AND fyear = 2024;

-- These are firms with NULL value of sales
-- In other words, the value of sale is missing
SELECT
	gvkey,
	fyear,
	conm,
	sale
FROM Fundamentals_Annual
WHERE sale IS NULL AND fyear = 2024;

--Using summary statistics
--What was the average value of sales for US firms in 2024?
SELECT 
	AVG(sale) AS sales_avg
FROM Fundamentals_Annual
WHERE fyear = 2024 AND loc = "USA";

--Now, what was average sales for US firms in 2024 with sales>0?
SELECT 
	AVG(sale) AS sales_avg 
FROM Fundamentals_Annual
WHERE fyear = 2024 AND loc = "USA" AND sale>0;

--Financial firms
--Financial firms means that the first two digits of NAICSH are 52
--A % character is a "wild card" that can represent any number of characters including zero
SELECT
	gvkey,
	fyear,
	conm,
	naicsh
FROM Fundamentals_Annual
WHERE naicsh LIKE "52%";

--Nonfinancial firms
SELECT
	gvkey,
	fyear,
	conm,
	naicsh
FROM Fundamentals_Annual
WHERE naicsh NOT LIKE "52%";

-- In-class Exercise 1 Q1 
-- What was Amazon's average return on assets (net income divided by total assets) 
SELECT 
	gvkey,
	fyear,
	tic,
	ni,
	at,
	AVG(100*ni/at) AS roa_avg
FROM Fundamentals_Annual
WHERE fyear >=2015 AND fyear<=2024 
AND tic = "AMZN";

-- In-class Exercise 1 Q2
-- How many employees did Amazon have in 1996 and in 2024 respectively?
SELECT 
	gvkey,
	fyear,
	tic,
	emp
FROM Fundamentals_Annual
WHERE fyear = 1996
AND tic = "AMZN";

-- In-class Exercise 1 Q3
-- What was the average ROA (net income/assets) for nonfinancial, 
-- US-headquartered (loc = 'USA') firms in 2024? 

SELECT 
	gvkey,
	fyear,
	tic,
	ni,
	at,
	AVG(100*ni/at) AS roa_avg
FROM Fundamentals_Annual
WHERE fyear = 2024
AND loc = "USA"
AND naicsh NOT LIKE "52%";

-- In-class Exercise 1 Q4
-- What was the average ROA (net income/assets) for nonfinancial, 
-- US-headquartered (loc = 'USA') firms with at least $50 million in assets in 2024?
SELECT 
	gvkey,
	fyear,
	tic,
	ni,
	at,
	AVG(100*ni/at) AS roa_avg
FROM Fundamentals_Annual
WHERE naicsh NOT LIKE "52%"
AND loc = "USA"
AND at >= 50
AND fyear = 2024;




-- Hands-on Exercises
-- What was the average ROA (net income/assets) for nonfinancial, 
-- US-headquartered (loc = 'USA') firms with at least $1 billion in assets in 2024?
SELECT 
	gvkey,
	fyear,
	tic,
	ni,
	at,
	AVG(100*ni/at) AS roa_avg
FROM Fundamentals_Annual
WHERE naicsh NOT LIKE "52%"
AND loc = "USA"
AND at >= 1000
AND fyear = 2024;