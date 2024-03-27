-- SDG 15 Data Cleaning

-- Step 1: data cleaning

SELECT * 
FROM deforestation_data 
;

-- Checking for null values

SELECT *
FROM deforestation_data
WHERE trend = ''
;

-- Having null values in the "trend" column does not denote that the data is bad, there could just be no change
-- to check this, let's make sure the two forests columns are not null.

SELECT
forests_2000,
forests_2020
FROM (
	SELECT *
FROM deforestation_data
WHERE trend = ''
) AS null_values
WHERE forests_2000 = ''
;

SELECT
forests_2000,
forests_2020
FROM (
	SELECT *
FROM deforestation_data
WHERE trend = ''
) AS null_values
WHERE forests_2020 = ''
;

-- Great, it looks like there are no null or missing values in the forest percentage columns.

SELECT * 
FROM deforestation_data 
;

-- Now let's make sure the country name column does not have values larger than 3 characters, and does not have missing values

ALTER TABLE deforestation_data
RENAME COLUMN iso3c to country_code
;

SELECT * 
FROM deforestation_data 
WHERE country_code IS NULL
;

SELECT *
FROM deforestation_data
WHERE
	LENGTH(country_code) <> 3
    ;

UPDATE deforestation_data
SET Country_code = ltrim(rtrim(country_code))
;

SELECT * 
FROM deforestation_data 
;

-- Now let's check for duplicate rows

SELECT COUNT(Country_code), Country_code
FROM deforestation_data
Group By Country_Code
;

SELECT COUNT(Country_code), Country_code
FROM deforestation_data
Group By Country_Code
HAVING COUNT(Country_code) <> 1
;

SELECT COUNT(Country_code), Country_code
FROM deforestation_data
GROUP BY Country_code
;

-- Great! This is a shorter data table, so it's easy for us to jump right into the EDA.

-- First, let's find the top 10 nations with the most dramatic forest loss.

SELECT Country_code, 
trend, 
forests_2000,
forests_2020
FROM deforestation_data 
order by trend ASC
Limit 10
;

-- Even from this simple query, it's easy to tell that the trend isn't always telling of how bad the impact of deforestation is in a land
-- for example, Egypt has 100% forest loss, but only started with 0.1% of it's landmass or 70,000 hectares

-- Now let's find the top 10 countries with greatest upward trend in forest growth

SELECT Country_code, 
trend, 
forests_2000,
forests_2020
FROM deforestation_data 
order by trend DESC
Limit 10
;

-- Even at a cursory glance, we can see that the spread for forest growth is far more varied than deforestation. These are most likely smaller, less industrialized countries.
-- Using Tableau, we can find more insights in regards to regional patterns, time series analyses, and do visual comparisons of forest loss and gains.
-- Let's start with the first question: what are the top 10 nations with the most dramatic forest loss

SELECT country_code,
trend
FROM deforestation_data 
ORDER BY trend ASC
LIMIT 10
;

-- Now let's use the DESC order to find the top 10 nations with the most forest growth

SELECT country_code,
trend
FROM deforestation_data 
ORDER BY trend DESC
LIMIT 10
;

-- Great. Finally, let's find the percentage of countries that have been able to increase or decrease their forest coverage over a 20 year span. Let's start with those that lost forest coverage


SELECT country_code,
trend,
 COUNT(country_code) OVER () AS total_rows
FROM deforestation_data
WHERE trend < 0
ORDER BY trend DESC
;

-- This shows us there are 95 countries with a decrease in forest area

SELECT country_code,
trend,
 COUNT(country_code) OVER () AS total_rows
FROM deforestation_data
WHERE trend > 0
ORDER BY trend DESC
;

-- And this data shows us that there are 87 countries that either have positive forest growth in the 20 year period. Almost an equal amount of forest loss and growth!

SELECT country_code,
trend,
 COUNT(country_code) OVER () AS total_rows
FROM deforestation_data
WHERE trend = 0
ORDER BY trend DESC
;

-- Finally, there are 45 countries that either have no forest growth, no forests at all, or do not have applicable data to analyze. 


SELECT * 
FROM deforestation_data 
;

-- Now, let's just assume that the "forests_2000" and "forests_2020" columns were not percentages, but in fact an area of land mass such as hectares or kilometers squared.
-- If we wanted to find a total area of that land mass that was deforested land, we could use the below query.

SELECT country_code,
forests_2000,
forests_2020,
trend,
Round((forests_2020 - forests_2000), 1) AS country_forest_loss
FROM deforestation_data
WHERE trend < 0
ORDER BY trend DESC
;

-- Now, let's add a window function with SUM to find a rolling total for total forest loss


SELECT country_code,
forests_2000,
forests_2020,
trend,
Round((forests_2020 - forests_2000), 1) AS country_forest_loss,
    Round(SUM(Round((forests_2020 - forests_2000), 1)) OVER (ORDER BY trend ASC), 1) AS rolling_total
FROM deforestation_data
WHERE trend < 0
ORDER BY trend DESC
;

-- Now, we can do the opposite to find the total land area that had forest growth. 

SELECT country_code,
forests_2000,
forests_2020,
trend,
Round((forests_2020 - forests_2000), 1) AS country_forest_loss,
    Round(SUM(Round((forests_2020 - forests_2000), 1)) OVER (ORDER BY trend ASC), 1) AS rolling_total
FROM deforestation_data
WHERE trend > 0
ORDER BY trend DESC
;


-- Nice! If we had more data such as the land mass that was lost to deforestation, we could use the above queries to find the sum total of that loss or gain.
-- Fortunately for us, there are lists of the ISO 3166 Country codes in CSV format available for download online. Let's bring in a table of these to see if we can do more EDA!


SELECT *
FROM deforestation_data as d
INNER JOIN iso_3166_codes as i
On d.country_code = i.`alpha-3`
;

-- Great, we've imported the entire set. It looks like there are several columns we will not need, however. Let's clean this set up a bit.

ALTER TABLE iso_3166_codes
DROP COLUMN `iso_3166-2`,
DROP COLUMN `region-code`,
DROP COLUMN `sub-region-code`,
DROP COLUMN `intermediate-region-code`
;

-- finally, Let's group by the different regions to determine which areas had the most amount of deforestation. 
-- first let's find the average trend per region.

SELECT 
i.region,
AVG(d.trend) AS avg_trend_per_region
FROM 
deforestation_data AS d
INNER JOIN 
iso_3166_codes AS i ON d.country_code = i.`alpha-3`
GROUP BY 
i.region
ORDER BY 
avg_trend_per_region
;

-- Here we can see that Africa has the highest average loss of forests, where Europe has experienced a large increase in their forest growth.
-- Note that these values are not indicative of the total land mass lost, but percentages of total forests per region lost. 