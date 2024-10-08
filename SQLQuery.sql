
select * from  Crop_Production


-- Finding Null values
SELECT *
FROM Crop_Production
WHERE Production IS NULL;


-- Deleting data of null values
DELETE FROM Crop_Production
WHERE Production IS NULL;



--  1) Top 3 Crops for each state based on production
	WITH rankedcrops AS (
		SELECT *, DENSE_RANK() OVER(PARTITION BY state_name ORDER BY production DESC) as production_rank
		FROM Crop_Production
	)
	SELECT state_name, crop, production
	FROM rankedcrops 
	WHERE production_rank <= 3
    

-- 2) Average area cultivated
SELECT 
    Crop,
    round(AVG(Area),2) AS Average_Area_Cultivated
FROM Crop_Production
WHERE Area IS NOT NULL
GROUP BY Crop
ORDER BY round(AVG(Area),2) desc;


-- 3) What are the most produced crops in each season across all states?
WITH RankedCrops AS (
SELECT 
	state_name,
	season,
	crop,
	sum(production) as total_production,
	DENSE_RANK() OVER (PARTITION BY state_name, Season ORDER BY SUM(Production) DESC) AS Production_Rank
FROM crop_production
WHERE 
	production is not null
GROUP BY 
	state_name, Season, Crop
)
SELECT State_Name, Season, Crop
FROM rankedcrops
WHERE Production_Rank = 1 and season = 'whole year'



-- 4) How has the total production of crops changed year-over-year?
WITH YearlyProduction AS (
    SELECT 
        Crop_Year,  
        ROUND(SUM(Production), 2) AS Total_Production
    FROM Crop_Production
    WHERE Production IS NOT NULL
    GROUP BY Crop_Year
),
YearlyChange AS (
    SELECT 
        Crop_Year, 
        Total_Production, 
        LAG(Total_Production, 1) OVER (ORDER BY Crop_Year) AS Previous_Year_Production
    FROM YearlyProduction
)
SELECT 
    Crop_Year, 
    Total_Production,
    Previous_Year_Production,
    CASE 
        WHEN Previous_Year_Production IS NULL THEN NULL
        ELSE ROUND(((Total_Production - Previous_Year_Production) * 100.0 / Previous_Year_Production), 2) 
    END AS Percentage_Change
FROM YearlyChange;



-- 5) Top district in each State by production wise
WITH total_production AS (
    SELECT 
        state_name, 
        district_name, 
        SUM(production) AS total_production
    FROM crop_production
    GROUP BY state_name, district_name
),
rank_district AS (
    SELECT 
        state_name, 
        district_name, 
        total_production,
        DENSE_RANK() OVER (PARTITION BY state_name ORDER BY total_production DESC) AS rnk
    FROM total_production
)
SELECT 
    state_name, district_name AS top_district
FROM rank_district
WHERE rnk = 1;




-- 6) total production and area in each year and season
select crop_year, round(avg(area),2) as avg_area, round(sum(production),2) as total_production
from crop_production
group by  crop_year
order by round(avg(area),2)  desc   , round(sum(production),2) asc



-- 7) Calculate crop yield (production per unit area) for each crop and analyze which crops have the highest yields.
WITH TotalAreaProduction AS (
    SELECT 
        Crop,
        SUM(Production) AS Total_Production,
        SUM(Area) AS Total_Area
    FROM  Crop_Production
    WHERE Production IS NOT NULL AND Area IS NOT NULL
    GROUP BY Crop
)
SELECT 
    Crop,
    ROUND(Total_Production /COALESCE(NULLIF(Total_Area, 0), null), 2) AS Crop_Yield 
FROM TotalAreaProduction
ORDER BY Crop_Yield DESC;




-- 8) What are the highest produced crops in each district of India, along with the total production for each district?
WITH DistrictProduction AS (
    SELECT 
        state_name, District_Name,
        SUM(Production) AS Total_Production
    FROM 
        Crop_Production
    WHERE 
        Production IS NOT NULL
    GROUP BY 
       state_name, District_Name
),
HighestCrops AS (
    SELECT 
        District_Name,
        Crop,
        SUM(Production) AS Crop_Production,
        RANK() OVER (PARTITION BY District_Name ORDER BY SUM(Production) DESC) AS Production_Rank
    FROM 
        Crop_Production
    WHERE 
        Production IS NOT NULL
    GROUP BY 
        District_Name, Crop
)
SELECT dp.state_name,
    dp.District_Name,
    dp.Total_Production,
    hc.Crop AS Highest_Produced_Crop
FROM 
    DistrictProduction dp
JOIN 
    HighestCrops hc ON dp.District_Name = hc.District_Name
WHERE 
    hc.Production_Rank = 1;
