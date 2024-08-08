select * from startup_stage;

-- Check Schema
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'startup_stage';


-- check for duplicates
select name, count(*) as dulpicate
from startup_stage
group by name
having count(*) >1;


-- Remove duplicates while keeping the non-empty row
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY name ORDER BY CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS row_num
    FROM startup_stage
)
-- Delete rows where row number is greater than 1, i.e., duplicates with empty data
DELETE FROM CTE
WHERE row_num > 1;



-- Count the number of startups
SELECT COUNT(DISTINCT name) AS unique_count
FROM startup_stage;


-- Basic Statitics
SELECT 
    SUM(funding_total_usd) AS total_funding,
    AVG(funding_total_usd) AS average_funding,
    MIN(funding_total_usd) AS min_funding,
    MAX(funding_total_usd) AS max_funding
FROM startup_stage;



-- Calculate average funding amount per round
SELECT TOP 10
    name,
    AVG(funding_total_usd) AS avg_funding_amount
FROM startup_stage
GROUP BY name
order by avg_funding_amount desc;


-- Distribution of funding amounts by range
SELECT 
    CASE 
        WHEN funding_total_usd < 1000000 THEN 'Under 1M'
        WHEN funding_total_usd BETWEEN 1000000 AND 5000000 THEN '1M to 5M'
        WHEN funding_total_usd BETWEEN 5000000 AND 10000000 THEN '5M to 10M'
        ELSE 'Over 10M'
    END AS funding_range,
    COUNT(*) AS count_startups
FROM startup_stage
GROUP BY 
    CASE 
        WHEN funding_total_usd < 1000000 THEN 'Under 1M'
        WHEN funding_total_usd BETWEEN 1000000 AND 5000000 THEN '1M to 5M'
        WHEN funding_total_usd BETWEEN 5000000 AND 10000000 THEN '5M to 10M'
        ELSE 'Over 10M'
    END;



-- Count startups by category
SELECT Top 10
category_list, COUNT(*) AS count_startups 
FROM startup_stage
GROUP BY category_list
ORDER BY count_startups DESC;




-- Funding amount per Round
SELECT TOP 10
    name,
    funding_total_usd / funding_rounds AS funding_per_round
FROM startup_stage;



--  Time between funding rounds
SELECT TOP 10
    name,
    DATEDIFF(day, first_funding_at, last_funding_at) / (funding_rounds - 1) AS avg_days_between_rounds
FROM startup_stage
WHERE funding_rounds > 1;

delete from startup_stage
where country_code IS NULL;


-- Count of startups by status for each country
SELECT Top 10
    country_code,
    status,
    COUNT(*) AS count_startups
FROM startup_stage
GROUP BY country_code, status
ORDER BY country_code, status;


--- Select rows with specific country_code values and count startups by status
SELECT 
    country_code,
    status,
    COUNT(*) AS count_startups
FROM startup_stage
WHERE country_code IN ('PAK', 'IND', 'USA')
GROUP BY country_code, status
ORDER BY country_code, status;


-- Calculate success and failure counts and their ratio with 2 decimal places for each country
WITH status_counts AS (
    SELECT 
        country_code,
        status,
        COUNT(*) AS count_startups
    FROM startup_stage
    WHERE country_code IN ('PAK', 'IND', 'USA')
    GROUP BY country_code, status
),
success_failure_counts AS (
    SELECT
        country_code,
        SUM(CASE WHEN status IN ('operating', 'ipo') THEN count_startups ELSE 0 END) AS success_count,
        SUM(CASE WHEN status IN ('closed', 'acquired') THEN count_startups ELSE 0 END) AS failure_count
    FROM status_counts
    GROUP BY country_code
)
SELECT
    country_code,
    success_count,
    failure_count,
    CASE 
        WHEN failure_count > 0 THEN ROUND(success_count * 1.0 / failure_count, 2)
        ELSE NULL
    END AS success_to_failure_rate
FROM success_failure_counts
ORDER BY country_code;



