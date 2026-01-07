-- ============================================================
-- Key SQL techniques:

-- Creating and dropping VIEWs to simplify complex or recurring queries
-- INNER JOIN to merge tables/views based on primary keys
-- Filtering using numeric ranges and logical operators
-- Using GROUP BY with aggregate functions (AVG) to summarize per-firm metrics
-- Calculating ratios (ROA = ni / at * 100)
-- Handling non-missing values (IS NOT NULL)
-- Merging aggregated results for combined analyses
-- Identifying primary keys for tables/views
-- Ordering results with ORDER BY
-- ============================================================

--Creating a VIEW for some 2020-2022 data
--Here, we are using gvkey, fyear, conm, ni

DROP VIEW IF EXISTS example20_22; --Or Database Structure > Delete View
CREATE VIEW example20_22 AS
	SELECT 
		gvkey,
		fyear,
		conm,
		ni
	FROM Fundamentals_Annual
	WHERE fyear >= 2020 AND fyear <= 2022;
-- Browse Data > Table > Drop-down column select the view

SELECT *
FROM example20_22;

--Creating a VIEW for the 2022-24 data
--Here we use gvkey, fyear, at and sale
DROP VIEW IF EXISTS example22_24;
CREATE VIEW example22_24 AS
	SELECT
		gvkey,
		fyear,
		at,
		sale
	FROM Fundamentals_Annual
	WHERE fyear >= 2022 AND fyear <= 2024;
	
--An INNER JOIN
--Available if the available names are the same in both tables
--The JOIN is based on the combination of gvkey and fyear
SELECT *
FROM example20_22
INNER JOIN example22_24
USING (gvkey, fyear)
ORDER BY fyear, conm;
-- The first is the dominant order, and the second sorts within each fyear (tie-breaker)

--An INNER JOIN with the ON statement
--gvkey and fyear are from the "left" TABLE
--The rest of the variables don't need to be specified in terms of which table they are from
--In other words, each variable comes from only one of the tables
--The JOIN is on the combination of gvkey and fyear

SELECT
	example20_22.gvkey,
	example20_22.fyear,
	conm,
	ni,
	at,
	sale
FROM example20_22
INNER JOIN example22_24
	ON example20_22.gvkey = example22_24.gvkey
	AND example20_22.fyear = example22_24.fyear;

-- Not equals to
SELECT
	gvkey,
	fyear,
	conm,
	sale,
	loc
FROM Fundamentals_Annual
WHERE loc != 'USA';

SELECT
	gvkey,
	fyear,
	conm,
	sale,
	loc
FROM Fundamentals_Annual
WHERE loc <> 'USA';




--Hands-on Exercises
-- Q1
--Start with the full North American Stock Market 1990-2024 database and examine the Fundamentals_Annual table. 
--Keep observations from fiscal years 2022 and 2023. 
--Also, keep observations as long as they have at least $10 million in assets and sales from those years. 
--Note that assets and sales are in millions of dollars and are denoted by at and sale, respectively.
--Finally, keep the variables gvkey, fyear, conm, at, and sale.
--What variable(s) would be the primary key for the results table? 
--Remember, the unique identifier (primary key) is the variable (or the minimum combination of variables) that uniquely identifies each observation. 
--No two observations share the same value(s) of the unique identifier (otherwise, it is not unique =)

-- Q2
--How many observations are in the results for the query that you ran in question 1?

DROP VIEW IF EXISTS example22_23;
CREATE VIEW example22_23 AS
	SELECT gvkey, fyear, conm, at, sale
	FROM Fundamentals_Annual
	WHERE (fyear = 2022 or fyear = 2023)
	AND at >= 10
	AND sale >= 10;


-- Q3
--Now, start again with the full Fundamentals_Annual table. 
--Keep observations from fiscal years 2023 and 2024. 
--Also, if an observation has $100 million or more in assets and sales in that year, keep it. 
--Otherwise, it is dropped.
--Keep the variables gvkey, fyear, tic, and ni.
--How many observations are a result of this query?

Keep the variables gvkey, fyear, tic, and ni.

How many observations are a result of this query?
DROP VIEW IF EXISTS example23_24;
CREATE VIEW example23_24 AS
	SELECT gvkey, fyear, tic, ni
	FROM Fundamentals_Annual
	WHERE (fyear = 2023 or fyear = 2024)
	AND at >= 100
	AND sale >= 100;
	
-- Q4
--Suppose you merged the results from questions 2 and 3 by the primary keys of those tables, 
--and keeping only the matching rows. 
--How many observations are there in the merged results table?
SELECT *
FROM example22_23
INNER JOIN example23_24
USING (gvkey, fyear);

-- Q5
--Start with the full Fundamentals_Annual table again. 
--Keep observations with $50 million or more in assets and sales and non-missing values of employment and net income (emp and ni, respectively, in the table).
--We want the results to be condensed (note: use a GROUP BY here) so that you have only two variables (fields). 
--The first is gvkey, and the second is ROA_avg, the average ROA for that gvkey across all of its observations in the results table.
--What is the primary key of the results table?

-- Q6
--Continue with the previous question. How many observations from the table you generated above?
DROP VIEW IF EXISTS example_ROA;
CREATE VIEW example_ROA AS
SELECT gvkey, 
	AVG(ni/at*100) as ROA_avg
	FROM Fundamentals_Annual
	WHERE at >= 50
	AND sale >= 50
	AND emp NOT NULL
	AND ni NOT NULL
	GROUP BY gvkey;
	
-- Q7
--Now, what is the average of those ROA averages? 
--In other words, for the ROA_avg values for each gkvey you created above, 
--what is the average of all of those values? 
--Round to three decimal places. Hint: the answer is a negative number.
SELECT AVG(ROA_avg) 
FROM example_ROA;

-- Q8
--Now, start with the full Fundamentals_Annual table again. Keep observations with non-missing values of employment (emp). 
--For each firm, calculate a per-firm employment average over the entire sample period, called emp_avg. 
--(Like before, use the GROUP BY statement to achieve this.)
--How many observations are there in this query?
DROP VIEW IF EXISTS example_emp;
CREATE VIEW example_emp AS
SELECT gvkey,
	AVG(emp) AS emp_avg
	FROM Fundamentals_Annual
	WHERE emp NOT NULL
	GROUP BY gvkey;

-- Q9
--What is the average of the many of per-firm employment averages you calculated above for firms with a four-digit gvkey?
SELECT
	AVG(emp_avg)
	FROM example_emp
	WHERE gvkey >= 1000 AND gvkey<=9999;

-- Q10
--Finally, merge the results from the ROA average and employment average tables 
--(from questions 5 and 8, respectively) you generated using an INNER JOIN. 
--How many observations are there in the merged results?
SELECT *
FROM example_ROA
INNER JOIN example_emp
USING (gvkey);











