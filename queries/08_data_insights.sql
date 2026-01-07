-- ============================================================
-- Key SQL techniques:
-- SELECT and FROM to retrieve firm-level financial and executive compensation data
-- LEFT JOIN and USING to merge tables on common keys (gvkey, fyear)
-- WHERE for conditional filtering (year, location, industry, asset thresholds, non-missing values)
-- ORDER BY to sort results (e.g., by sales, CEO pay, total compensation)
-- AVG() and COUNT() aggregate functions, including use of OVER() for windowed calculations
-- NTILE() OVER() to divide firms into deciles by modified ROA or Tobin's q
-- Calculated fields for financial ratios (e.g., modified ROA = ni / (at + K_int_offBS))
-- DROP VIEW and CREATE VIEW to store intermediate query results for cohort analysis
-- ============================================================

--Intangible capital
--Our second Table
--That table is called "Total_Q"
--Peters and Taylor Total q dataset covers intangible assets through 2023

--Tobin's q is market value divided by physical assets
--Peters and Taylor Total Q is market value divided by (physical + intangible) assets 
--If q is above 1, the market value is high compared to physical assets; 
--If it = 1, then market value is exactly at value of physical assets;
--If Total q is less than 1, then might be very poor organizational administration

--Most intangible assets are missing from the balance sheet
--Except for goodwill -- externally purchased intangible capital

--Knowledge capital: Accumulated R&D spending, depreciated at approx. 15%/yr
--Organizational capital: Use 30% of SG&A spending - assume that it is long-term investment
--Then the organizational capital flows get depreciated at 20%/year

--Relative size of tangible and intangeble capital

--1990
SELECT
	gvkey,
	fyear,
	conm,
	sale,
	ppent,                        -- property plant equipment, value of physical capital
	K_int_Know,
	K_int_Org,
	K_int_offBS,
	K_int,
	q_tot
FROM Fundamentals_Annual
LEFT JOIN Total_Q                 --Financial firms have weird q's
USING (gvkey, fyear)
WHERE fyear = 1990
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
ORDER BY sale DESC;

--2023
SELECT
	gvkey,
	fyear,
	conm,
	sale,
	ppent,                        
	K_int_Know,
	K_int_Org,
	K_int_offBS,
	K_int,
	q_tot
FROM Fundamentals_Annual
LEFT JOIN Total_Q                 
USING (gvkey, fyear)
WHERE fyear = 2023
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
ORDER BY sale DESC;

--What was average q for all nonfinancial US firms in 1990 and 2023?
--Then add the condition that assets are greater or equal to 100 million
--1990
SELECT
	gvkey,
	fyear,
	conm,
	loc,
	q_tot,
	AVG(q_tot) OVER() AS avg_q,
	COUNT(gvkey) OVER() AS cbs
FROM Fundamentals_Annual
LEFT JOIN Total_Q
USING (gvkey, fyear)
WHERE fyear = 1990
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%';
	
--1990 & assets >= $100 mil (Fundamentals_Annual unit is millions)
SELECT
	gvkey,
	fyear,
	conm,
	loc,
	q_tot,
	AVG(q_tot) OVER() AS avg_q,
	COUNT(gvkey) OVER() AS cbs
FROM Fundamentals_Annual
LEFT JOIN Total_Q
USING (gvkey, fyear)
WHERE fyear = 1990
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND at >= 100;

	
--2023	
--weird things happen with small firms, so avg_q is much higher when asset is not restricted to be high
SELECT
	gvkey,
	fyear,
	conm,
	loc,
	q_tot,
	AVG(q_tot) OVER() AS avg_q,
	COUNT(gvkey) OVER() AS cbs
FROM Fundamentals_Annual
LEFT JOIN Total_Q
USING (gvkey, fyear)
WHERE fyear = 2023
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%';
	
--1990 & assets >= $100 mil
SELECT
	gvkey,
	fyear,
	conm,
	loc,
	q_tot,
	AVG(q_tot) OVER() AS avg_q,
	COUNT(gvkey) OVER() AS cbs
FROM Fundamentals_Annual
LEFT JOIN Total_Q
USING (gvkey, fyear)
WHERE fyear = 2023
	AND loc = 'USA'
	AND naicsh NOT LIKE '52%'
	AND at >= 100;

--Insight from comparing 1990 and 2023:
--avg_q is much higher than 1990
--Either market value is too high (AI bubble)
--Or the assets are too low/not always recognized on the balance sheet in 2023

--Executive Compensation (Execucomp unit is thousands)
--Covers roughly the S&P 1500 (since 1994), the S&P 500 in 1993
--Most data is on five executives per year
--CEO, CFO plus the three other highest paid.
--From SEC 14A: Definitive Proxy Statement.

--Rule changes since 2006 affects the data since then.
--Some variables only begin then.

--Compustat generated variables
--co_per_rol is a unique ID number for each person-firm combination
--execid is a unique ID for each person.

--Compensation variables we'll start with
--Measured in thousands of dollars
--total_curr is salary + bonus
--tdc1 is total compensation: salary, bonus, incentives, benefits, stock options, etc.

--Our first query:
SELECT
	gvkey,
	fyear,
	coname,
	execid,
	co_per_rol,
	exec_fullname,
	total_curr,
	salary,
	bonus,
	othcomp,
	tdc1
FROM Execucomp;

--What is the average pay for top five executives in 2024?
SELECT
	fyear,
	AVG(total_curr) AS avg_cur_salary,
	AVG(tdc1) AS avg_total_pay
FROM Execucomp
WHERE fyear = 2024;

--What is the average pay for top five executives in 1992?
SELECT
	fyear,
	AVG(total_curr) AS avg_cur_salary,
	AVG(tdc1) AS avg_total_pay
FROM Execucomp
WHERE fyear = 1992;

--What is the average pay for top five executives in 2007?
SELECT
	fyear,
	AVG(total_curr) AS avg_cur_salary,
	AVG(tdc1) AS avg_total_pay
FROM Execucomp
WHERE fyear = 2007;

--Now, we turn to CEO pay.
--ceoann is a variable equal to 'CEO' if this exective was the CEO in that year.
--Or, for most of the year.
--execdir = 1 if this individual was Executive Director for most of the year.

--Examine CEO and Executive Director Data                        
SELECT
	gvkey,
	fyear,
	coname,
	execid,
	co_per_rol,
	exec_fullname,
	total_curr,
	tdc1
FROM Execucomp
WHERE ceoann = 'CEO' AND execdir = 1;   --So that's the real owner of the firm (CEO and Exective Director the same person for most of the year)

--What is the average proportion of CEO total compensation is "salary and bonus" in 2007?
SELECT
	fyear,
	AVG(total_curr/tdc1) AS salary_proportion
FROM Execucomp
WHERE fyear = 2007 AND ceoann = 'CEO' AND execdir = 1;

--What is the average  proportion of CEO total compensation is "salary and bonus" in 2024?
SELECT
	fyear,
	AVG(total_curr/tdc1) AS salary_proportion
FROM Execucomp
WHERE fyear = 2024 AND ceoann = 'CEO' AND execdir = 1;
--For example, when the CEO holds stock options, they might use their salary to buy stock options for the value of the firm to raise, and to save taxes.

--Merge the Exective Compensation data with the main table - Fundamentals_Annual
--How many firms in 2024 had CEO compensation data?
--Order by highest paid CEOs in descending order
SELECT
	gvkey,
	fyear,
	coname,
	exec_fullname,
	ceoann,
	total_curr,
	tdc1
FROM Fundamentals_Annual
LEFT JOIN Execucomp
USING (gvkey, fyear)
WHERE ceoann = 'CEO' AND execdir = 1 AND fyear =2024
ORDER BY tdc1 DESC;
--Changes in own wealth is not included
--The CEO’s personal wealth increases due to appreciation of previously granted stock/option holdings.
--But TDC1 stays the same, because TDC1 only records new compensation granted this year, not changes in the market value of past grants.












--Hands-on Exercises
--Q1
--Start with all US nonfinancial firms from 2023 as your sample, and only keep observations with at least $1 billion in assets, 
--non-missing employment, sales, net income, and total q (q_tot) based on Peters and Taylor's total q.
--We will define a modified ROA as net income divided by total assets (at) plus intangible assets that are not on the balance sheet (K_int_offBS)
--Sort the sample into deciles by modified ROA (ni/(at + K_int_offBS)) for the top 10%, ROA for the next 10%, etc., all the way down to ROA for the bottom 10%.
--What is the average modified ROA for the top 10% of firms by modified ROA? Write your answer as a percentage, round to the nearest tenth of a percent. 
--For example, write 9.92 as 9.9.

SELECT 
	AVG(modified_ROA_pct) AS modified_ROA_pct_avg
	FROM(
	SELECT 
		*,
		NTILE(10) OVER(PARTITION BY fyear ORDER BY modified_ROA_pct DESC) AS decile_roa
		FROM
			(SELECT
				*,
				ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
			FROM Fundamentals_Annual
			LEFT JOIN Total_Q
			USING (gvkey, fyear)
			WHERE naicsh NOT LIKE '52%'
				AND at >= 1000
				AND emp IS NOT NULL
				AND sale IS NOT NULL
				AND ni IS NOT NULL
				AND q_tot IS NOT NULL
				AND fyear >= 2023
				AND loc = 'USA')
				)
	WHERE decile_roa = 1
;
 

--Q2
--Note: Use modified ROA as your ROA for this and all subsequent questions.
--Modified ROA is: (ni/(at + K_int_offBS))
--For the same sample as above, what is the average modified ROA for the bottom 10% of firms (by modified ROA)? 
--Write your answer as a percentage, round to the nearest tenth of a percent. For example, write 9.92 as 9.9.

SELECT 
	AVG(modified_ROA_pct) AS modified_ROA_pct_avg
	FROM(
	SELECT 
		*,
		NTILE(10) OVER(PARTITION BY fyear ORDER BY modified_ROA_pct DESC) AS decile_roa
		FROM
			(SELECT
				*,
				ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
			FROM Fundamentals_Annual
			LEFT JOIN Total_Q
			USING (gvkey, fyear)
			WHERE naicsh NOT LIKE '52%'
				AND at >= 1000
				AND emp IS NOT NULL
				AND sale IS NOT NULL
				AND ni IS NOT NULL
				AND q_tot IS NOT NULL
				AND fyear = 2023
				AND loc = 'USA')
				)
	WHERE decile_roa = 10
;

--Q3
--In parallel, divide up this same sample of firms (as you calculated in question 1) from 2023 by total q (q_tot) based on Peters and Taylor's total q. 
--Rank firms in deciles, from the highest 10% to the lowest 10% in terms of q_tot.
--What is the average modified ROA for firms in the top 10% of q_tot? Write your answer as a percentage, round to the nearest tenth of a percent. 
--For example, write 9.92 as 9.9.

SELECT 
	AVG(modified_ROA_pct) AS modified_ROA_pct_avg
	FROM(
	SELECT 
		*,
		NTILE(10) OVER(PARTITION BY fyear ORDER BY q_tot DESC) AS decile_q
		FROM
			(SELECT
				*,
				ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
			FROM Fundamentals_Annual
			LEFT JOIN Total_Q
			USING (gvkey, fyear)
			WHERE naicsh NOT LIKE '52%'
				AND at >= 1000
				AND emp NOT NULL
				AND sale NOT NULL
				AND ni NOT NULL
				AND q_tot NOT NULL
				AND fyear = 2023
				AND loc = 'USA')
				)
	WHERE decile_q = 1
;

--Q4
--What is the average modified ROA for firms in the bottom 10% of q_tot? 
--Write your answer as a percentage, round to the nearest tenth of a percent. For example, write 9.92 as 9.9.
SELECT 
	AVG(modified_ROA_pct) AS modified_ROA_pct_avg
	FROM(
	SELECT 
		*,
		NTILE(10) OVER(PARTITION BY fyear ORDER BY q_tot DESC) AS decile_q
		FROM
			(SELECT
				*,
				ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
			FROM Fundamentals_Annual
			LEFT JOIN Total_Q
			USING (gvkey, fyear)
			WHERE naicsh NOT LIKE '52%'
				AND at >= 1000
				AND emp NOT NULL
				AND sale NOT NULL
				AND ni NOT NULL
				AND q_tot NOT NULL
				AND fyear = 2023
				AND loc = 'USA')
				)
	WHERE decile_q = 10
;

--Q5
--Now, you want to do something truly epic. 
--You want to divide the 2014 stock market into deciles by q_tot and follow those firms over time. How will q_tot predict how they did later?
--So you now start with all US nonfinancial firms from 2014 as your sample, and only keep observations from that year with at least $1 billion in assets, 
--non-missing employment, sales, net income, and total q (q_tot) based on Peters and Taylor's total q.
--Divide the 2014 sample into deciles, from the top 10% of q_tot (decile number 10) down to the bottom 10% of q_tot (decile number 1).
--How many observations are there in this 2014 sample?
DROP VIEW IF EXISTS d2014;
CREATE VIEW d2014 AS
SELECT 
		*,
		NTILE(10) OVER(PARTITION BY fyear ORDER BY q_tot) AS decile_q_2014
		FROM
			(SELECT
				*,
				ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
			FROM Fundamentals_Annual
			LEFT JOIN Total_Q
			USING (gvkey, fyear)
			WHERE naicsh NOT LIKE '52%'
				AND at >= 1000
				AND emp NOT NULL
				AND sale NOT NULL
				AND ni NOT NULL
				AND q_tot NOT NULL
				AND fyear = 2014
				AND loc = 'USA')
;

SELECT COUNT() AS cnt FROM q5;

--Q6
--How many firms from that 2014 sample above exist in the 2023 Fundamentals_Annual table? 
--In other words, their gvkey appears in Fundamentals_Annual for 2023. 
--These firms do not have to have the same screening procedures applied in 2023 - you are just looking to see whether their gvkeys exist in 2023.
DROP VIEW IF EXISTS q6;
CREATE VIEW q6 AS
SELECT 
*
FROM Fundamentals_Annual
WHERE fyear = 2023
AND gvkey IN (SELECT gvkey from q5)
;

SELECT COUNT() FROM q6;

--Q7
--Lastly, which of those original ten groups from 2014 were among the top performers in terms of average modified ROA in 2023? 
--Write the decile numbers from the three winning groups in the boxes below.
--2014 cohort with the highest average modified ROA in 2023: 
--2014 cohort with the second-highest average modified ROA in 2023: 
--2014 cohort with the third-highest average modified ROA in 2023: 

DROP VIEW IF EXISTS d2023;
CREATE VIEW d2023 AS
SELECT 
*,
ni/(at+K_int_offBS) * 100 AS modified_ROA_pct
FROM Fundamentals_Annual
LEFT JOIN Total_Q
USING (gvkey, fyear)
WHERE fyear = 2023
AND gvkey IN (SELECT gvkey from q5)
;

SELECT * FROM (				
SELECT 
decile_q_2014,
AVG(modified_ROA_pct) AS roa_avg
FROM d2023
LEFT JOIN (SELECT gvkey, decile_q_2014 FROM d2014)
USING (gvkey)
GROUP BY decile_q_2014 )
ORDER BY roa_avg DESC;
