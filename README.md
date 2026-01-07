# SQL Data Analysis Portfolio

This repository demonstrates my SQL proficiency through a collection of analytical queries applied to real-world financial and company-level data. The work reflects my ability to use SQL to clean, transform, and analyze relational datasets in order to answer business-oriented questions.

## Overview

The repository contains SQL scripts developed during an advanced data preparation and analysis course. Each script addresses a specific analytical question and includes clearly commented SQL code that illustrates both the reasoning process and the technical approach.

The focus of this portfolio is on writing accurate, readable, and efficient SQL to extract insights from structured data.

## Datasets

The `data/` folder contains the datasets used in this project:

- **North_American_Stock_Market_1990-2024.db**  
  A relational database containing historical stock market and company-related data.

- **Execucomp_Data_Definitions.pdf**  
  A reference document describing variable definitions and data fields used in the database.

With these files provided, all SQL queries in this repository can be executed directly.

## Key SQL Skills Demonstrated

Across the SQL scripts, I demonstrate the ability to:

- Clean, filter, and prepare data using SQL
- Aggregate and summarize data for analysis
- Handle missing values and data inconsistencies
- Combine multiple tables using `JOIN`s
- Write subqueries and Common Table Expressions (CTEs)
- Apply window functions (e.g., `LAG`, `ROW_NUMBER`, `RANK`)
- Perform time-series and longitudinal analysis on financial data
- Translate analytical and business questions into structured SQL solutions

## Repository Structure

```
data/
├── North_American_Stock_Market_1990-2024.db
└── Execucomp_Data_Definitions.pdf

queries/
├── 01_data_filtering.sql
├── 02_grouping_and_aggregation.sql
├── 03_views_and_joins.sql
├── 04_joins_groupby_window.sql
├── 05_window_rank_case.sql
├── 06_cte_union_window.sql
├── 07_subqueries_fsp.sql
└── 08_data_insights.sql
```

## SQL Scripts

Each SQL file is self-contained and begins with comments describing:
- The analytical question being addressed
- The key SQL techniques used
- Any assumptions made during the analysis

The scripts are designed to be easy to read and review, allowing others to quickly understand both the problem and the solution approach.

## Purpose

This repository is intended to showcase my SQL skills for data analyst and analytics-focused roles, highlighting my ability to work with real datasets and derive insights using structured queries.
