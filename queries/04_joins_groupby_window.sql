-- ============================================================
-- Key SQL techniques:

-- Recreating and managing VIEWs for recurring queries
-- INNER JOIN and LEFT JOIN to merge tables/views while controlling which side is preserved
-- GROUP BY with multiple variables to summarize and condense data
-- Aggregate functions with GROUP BY (AVG, MIN, MAX, COUNT)
-- Window functions (OVER() and PARTITION BY) for rolling, grouped, or total calculations without collapsing rows
-- Calculating percentages within groups using window functions
-- Filtering for numeric ranges, non-missing values, and categorical variables
-- Identifying firms that change primary industry codes (DISTINCT + COUNT)
-- Screening datasets for analytical subsamples based on multiple criteria
-- ============================================================

DROP VIEW IF EXISTS example20_22;
CREATE VIEW example20_22 AS
	SELECT
		gvkey,
		fyear,
		conm,
		ni
	FROM Fundamentals_Annual
	WHERE fyear >= 2020 and fyear <= 2022;

--Recreate the view from 2022-24
DROP VIEW IF EXISTS example22_24;
CREATE VIEW example22_24 AS
	SELECT
		gvkey,
		fyear,
		at,
		sale
	FROM Fundamentals_Annual
	WHERE fyear >= 2022 and fyear <= 2024;
	
--INNER JOIN that we ran in Lecture 4

SELECT *
	FROM example20_22
	INNER JOIN example22_24
	USING (gvkey, fyear);
	
--LEFT JOIN using the 2022-22 as the "left" data
--We end up with 36,730 observations
--Exactly the same number as example20_22

--The LEFT JOIN keeps the "left" data intact
--It adds relevant data from the "right" data

DROP VIEW IF EXISTS example20_22_left;
CREATE VIEW example20_22_left AS
	SELECT * 
	FROM example20_22
	LEFT JOIN example22_24
	USING (gvkey, fyear);
	
--LEFT JOIN using the 2022-24 as the "left" data
--We end with 37,690 observations, same as the number in example22_24

DROP VIEW IF EXISTS example22_24_left;
CREATE VIEW example22_24_left AS
	SELECT * 
	FROM example22_24
	LEFT JOIN example20_22
	USING (gvkey, fyear);

--GROUP BY with two variables
--GROUP BY condenses the table
--You aren't in Kansas anymore after GROUP BY
--Here, we have all of the fiscal year-industry combinations
--There are 30,730 different combinations of fyear and naicsh
--The variable obs captures total observations in that group
--The variable obs_with_asset_data captures total observations with asset data in that group 

SELECT
	fyear,
	naicsh,
	AVG(at) AS at_avg,
	MIN(at) AS at_min,
	MAX(at) AS at_max,
	COUNT(gvkey) AS obs,
	COUNT(at) AS obs_with_asset_data
FROM Fundamentals_Annual
WHERE naicsh IS NOT NULL
	AND fyear IS NOT NULL
GROUP BY fyear, naicsh; 	
--NULL rows are automatically excluded from aggregate functions


--Continuing with WINDOW functions (OVER())
--Creating an extra column in the results table that is total assets

SELECT
	gvkey,
	fyear,
	conm,
	loc,
	at,
	SUM(at) OVER() AS total_at
FROM Fundamentals_Annual;

--Same query as before, total assets but now grouping by country and fyear
--This happens in an OVER() statement where we add PARTITION BY
--It acts like a "GROUP BY" inside an OVER() statement

SELECT
	gvkey,
	fyear,
	conm,
	loc,
	at,
	SUM(at) OVER(PARTITION BY fyear, loc) AS total_at
FROM Fundamentals_Annual
WHERE fyear IS NOT NULL
	AND loc IS NOT NULL
ORDER BY gvkey, fyear;

--What percentage of a country's assets (not including brand value) in a year does each observation represent?
--You can see intersting results by viewing in descending order
--We are using US nonfinancial firms

SELECT
	gvkey,
	fyear,
	conm,
	loc,
	at,
	100*at/SUM(at) OVER(PARTITION BY fyear, loc) AS at_pctage
FROM Fundamentals_Annual
WHERE fyear IS NOT NULL
	AND loc IS NOT NULL
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
ORDER BY fyear DESC, at_pctage DESC;




--Hands-on Exercises
--Q4
--Start with the whole North American Stock market database. 
--You are interested in studying firms that changed their primary industry 
--(as indicated by the naicsh variable in the dataset).
--First, consider observations that have a six-digit naicsh code.
--How many observations have a six-digit naicsh code?
--Remember in this question that we are looking for the total number of observations (rows), 
--not firms (as identified by their gvkey).

SELECT
	gvkey,
	naicsh
FROM Fundamentals_Annual
WHERE naicsh IS NOT NULL
	AND naicsh >= 100000
	AND naicsh <= 999999;

--Q5
--Continuing the previous question, How many firms (as denoted by gvkey) 
--that were in the sample above ever changed naicsh codes at any time in the dataset? 
--Recall that naicsh represents the primary industry code that the firm operates in.
--For example, AAR Corporation (gvkey 1004) changed its primary naicsh code from 421860 to 423860 in 2002. 
--That counts as one firm. Now all you have to do is find the rest. =)
--To clarify, if a firm ever changed its naicsh code, it counts just once. 
--Thus, no matter how many times a firm ever changed its naicsh code back and forth, 
--such a firm would count only once in this calculation.
SELECT
	gvkey,
	COUNT(DISTINCT(naicsh)) AS naicsh_cnt
FROM Fundamentals_Annual
WHERE naicsh IS NOT NULL
	AND naicsh >= 100000
	AND naicsh <= 999999
GROUP BY gvkey
HAVING naicsh_cnt >= 2;

--Q6
--Shifting gears, we will eventually examine firms that continually outperform their industry year after year.
--So first, let's do some screening. Start with the whole North American 1990-2024 database again,
--and keep all observations with $100 million or more in sales (sale), 
--$100 million or more in assets (at), a six-digit naicsh code (naicsh), 
--nonmissing employment (emp), and nonmissing net income (ni). 
--Finally, keep observations headquartered in the United States (loc = "USA").
--To make industry comparisons meaningful, we only keep observations in industries 
--with at least three firms after applying the screening criteria above, 
--within the same six-digit naicsh industry and year.
--How many observations satisfy these criteria? (Remember we are asking for observations here, 
--not firms..at least yet..we'll continue this next class..)
DROP VIEW IF EXISTS example20_22_left;
CREATE VIEW L5Q6 AS
	SELECT
		gvkey,
		naicsh,
		fyear,
		COUNT(gvkey) OVER (PARTITION BY naicsh, fyear) AS gvkey_cnt
	FROM Fundamentals_Annual
	WHERE sale >= 100
		AND at >= 100
		AND naicsh >= 100000
		AND naicsh <= 999999
		AND emp IS NOT NULL
		AND ni IS NOT NULL
		AND loc = 'USA';
		
SELECT *
FROM L5Q6
WHERE gvkey_cnt>= 3
;