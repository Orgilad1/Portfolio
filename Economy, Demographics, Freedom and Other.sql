-- Exploring three different datasets about countries' population, health, economies, and freedom scores and joining them for additional analysis.

-- This dataset contains general information about countries and about their economies:
select *
from [dbo].[Economy and Info]

-- This datast contains information about the SIZE OF POPULATION in each country as well as education, health and other demographics.
select *
from [dbo].[Population Education Health]

--This dataset contains information about the freedom score and freedom category of each country:
Select *
from [dbo].[Freedom Index]



--Lets explore the datasets:


-- Which are the most common official languages?
Select [Official language], count([Official language]) as [Official language total]
from [dbo].[Economy and Info]
Group by [Official language]
order by [Official language total] desc



-- How many currencies are used in more than one country?
SELECT COUNT(DISTINCT [Currency-Code]) AS [Total Currencies Used In More Than One Country]
FROM [dbo].[Economy and Info]
WHERE [Currency-Code] IN (
SELECT [Currency-Code]
FROM [dbo].[Economy and Info]
GROUP BY [Currency-Code]
HAVING COUNT(DISTINCT [Country]) > 1
)



-- Which official currency is used in the most countries?
Select [Currency-Code], count([Currency-Code]) as [Currency-Code total]
FROM [dbo].[Economy and Info]
Group by [Currency-Code]
order by [Currency-Code total] desc




--Which countries have the highest percentage of urban population? Let's create it as a TEMP TABLE:
DROP Table if exists #UrbanPopulationTable
Create Table #UrbanPopulationTable
(
Country nvarchar(255),
Population numeric,
Urban_population numeric,
UrbanPopPercentage float
)
Insert into #UrbanPopulationTable
Select country, population, Urban_population, (Urban_population/Population)*100 as UrbanPopPercentage
From [dbo].[Population Education Health]
Order by UrbanPopPercentage desc

Select *
From #UrbanPopulationTable
Order by UrbanPopPercentage DESC




-- In the 'Freedom Index' dataset, countries are separated into 3 different freedom categories. 
-- What are the categories and how many countries fall into each category?
SELECT [freedom in the world 2023], COUNT(*) AS CountryCount
FROM [dbo].[Freedom Index]
GROUP BY [freedom in the world 2023]


-- There are also 4 different categories specifying the type of regime of each country.
-- What are the categories and how many countries fall into each category?
SELECT [Democracy Index 2023], COUNT(*) AS CountryCount
FROM [dbo].[Freedom Index]
GROUP BY [Democracy Index 2023]



--Let's join the datasets for further analysis and insights.



--Let's examine the Co2 emissions per capita - which countries pollute the most in compairison to their population size?

Select [Pop].Country, ([Co2-Emissions]/Population) as [Co2-Emissions Per Capita]
From [dbo].[Population Education Health] as Pop
Inner join [dbo].[Economy and Info] as Eco on Eco.Country = Pop.Country
Order by [Co2-Emissions Per Capita] desc




--How much is the GDP per capita in each country and which countries have the highest/lowest?

Select [Pop].Country, (GDP/Population) as GDPPerCapita
From [dbo].[Population Education Health] as Pop
Inner join [dbo].[Economy and Info] as Eco on Eco.Country = Pop.Country
Order by GDPPerCapita desc




-- Let's look at the amount of people that live under each regime category.
-- How many people in the world live in democracies?

SELECT [Free].[Democracy Index 2023], SUM(Population)
FROM [dbo].[Freedom Index] AS Free
INNER JOIN [dbo].[Population Education Health] AS Pop ON Free.Country = Pop.Country
GROUP BY [Democracy Index 2023]
ORDER BY SUM(Population) DESC



-- Which Freedom category holds the most people (when adding the population of all of the countries in the category)?
-- How many people in the world live in free/partially free/not free countries?

SELECT [Free].[freedom in the world 2023] AS FreedomCategory, SUM([Population]) AS TotalPopulation
From [dbo].[Freedom Index] AS Free
JOIN [dbo].[Population Education Health] AS Pop ON Free.Country = Pop.Country
GROUP BY [Free].[freedom in the world 2023]
ORDER BY TotalPopulation DESC;



-- Which freedom category's countries pullote more in total?
SELECT [Free].[freedom in the world 2023] AS FreedomCategory, SUM([Co2-Emissions]) AS TotalCo2Emissions
FROM [dbo].[Freedom Index] AS Free
INNER JOIN [dbo].[Economy and Info] AS Eco ON Free.Country = Eco.Country
INNER JOIN [dbo].[Population Education Health] AS Pop ON Eco.Country = Pop.Country
GROUP BY [Free].[freedom in the world 2023]
Order by TotalCo2Emissions desc




-- CTE


-- What is the average popultion of countries in each freedom category?

WITH CTE_FreedomPopulation as
(SELECT [Free].[freedom in the world 2023] AS FreedomCategory, COUNT(*) AS CountryCount, SUM([Population]) AS TotalPopulation
From [dbo].[Freedom Index] AS Free
JOIN [dbo].[Population Education Health] AS Pop ON Free.Country = Pop.Country
GROUP BY [Free].[freedom in the world 2023]
)
Select FreedomCategory, (TotalPopulation/CountryCount) as AvgCountryPopulation
From CTE_FreedomPopulation
Order by AvgCountryPopulation desc





-- And how would the average population of the countries look like if we take out the 2 most populated countries in the world - China and India?

WITH CTE_FreedomPopulation AS (
SELECT 
[Free].[freedom in the world 2023] AS FreedomCategory,
COUNT(*) AS CountryCount,
SUM(CASE WHEN Pop.Country NOT IN ('China', 'India') THEN [Population] ELSE 0 END) AS TotalPopulation
FROM 
[dbo].[Freedom Index] AS Free
JOIN [dbo].[Population Education Health] AS Pop ON Free.Country = Pop.Country
GROUP BY 
[Free].[freedom in the world 2023]
)
SELECT 
FreedomCategory, 
AVG(TotalPopulation*1.0/CountryCount) as AvgCountryPopulation
FROM CTE_FreedomPopulation
GROUP BY FreedomCategory
ORDER BY AvgCountryPopulation DESC






-- Which freedom category holds the countries with the highest life expectancy, taking into consideration the population size of each country?

WITH CTE_LifeExpectancy AS
(
SELECT 
[Free].[freedom in the world 2023],
AVG([Life expectancy]) as LifeExpect,
[Population]
FROM 
[dbo].[Population Education Health] AS Pop
INNER JOIN [dbo].[Freedom Index] AS Free ON Free.Country = Pop.Country
GROUP BY [Free].[freedom in the world 2023], [Population]
)
SELECT 
[freedom in the world 2023], 
SUM([Population]*LifeExpect)/SUM([Population]) AS AvgLifeExpect
FROM 
CTE_LifeExpectancy
GROUP BY [freedom in the world 2023]
ORDER BY AvgLifeExpect DESC





-- How does the urban population percentage of countries affect their wealth?
-- Let's separate the countries to 3 different groups acording to the percentage of urban population (below 40%, between 40%-70%, above 70%). 
-- Now Let's compare the average GDP per capita of each group, with weighted average calculation (taking into consideration the population size of each country).

WITH CTE_UrbanPercentage AS(
SELECT 
Urban_population,
Population,
(Urban_population/Population)*100 as UrbanPopPercentage,
(GDP/Population) as GDPPerCapita,
CASE
WHEN (Urban_population/Population)*100 < 40 THEN 'Less than 40%'
WHEN (Urban_population/Population)*100 >= 40 AND (Urban_population/Population)*100 <= 70 THEN 'Between 40% and 70%'
WHEN (Urban_population/Population)*100 > 70 THEN 'Above 70%'
ELSE 'Unknown'
END AS UrbanPopGroup
FROM 
[dbo].[Population Education Health] as Pop
INNER JOIN 
[dbo].[Economy and Info] AS Eco ON Pop.Country = Eco.Country
)
SELECT 
UrbanPopGroup,
SUM(GDPPerCapita * Population) / SUM(Population) AS WeightedAvgGDPPerCapita
FROM CTE_UrbanPercentage
WHERE UrbanPopPercentage IS NOT NULL
GROUP BY UrbanPopGroup
ORDER BY WeightedAvgGDPPerCapita DESC





-- Which freedom category has countries that pollute the most per capita, taking into concideration the population size of each country?
-- Do the more free countries pollute more on average?


WITH CTE_Co2EmissionsPerCapita AS (
SELECT 
[Free].[freedom in the world 2023] AS FreedomCategory,
AVG([Co2-Emissions]/Population) as Co2PerCapita,
SUM(Population) AS TotalPopulation
FROM 
[dbo].[Freedom Index] AS Free
INNER JOIN [dbo].[Economy and Info] AS Eco ON Free.Country = Eco.Country
INNER JOIN [dbo].[Population Education Health] AS Pop ON Eco.Country = Pop.Country
GROUP BY [Free].[freedom in the world 2023]
)
SELECT FreedomCategory,
SUM(Co2PerCapita*TotalPopulation)/SUM(TotalPopulation) AS AverageCo2PerCapita
FROM CTE_Co2EmissionsPerCapita
GROUP BY FreedomCategory
ORDER BY AverageCo2PerCapita DESC





-- Which Freedom category has the countries with the highest GDP per capita on average, taking into consideration the population size of each country?

WITH CTE_GDPCap AS
(SELECT [Free].[freedom in the world 2023],
[Pop].Country, Population,
GDP/Population AS GDPPerCapita
FROM [dbo].[Population Education Health] AS Pop
INNER JOIN [dbo].[Economy and Info] AS Eco ON Eco.Country = Pop.Country
INNER JOIN [dbo].[Freedom Index] AS Free ON Free.Country = Pop.Country
)
SELECT [freedom in the world 2023], 
SUM([Population]*GDPPerCapita)/SUM([Population]) AS AverageGdpPerCapita
FROM CTE_GDPCap
GROUP BY [freedom in the world 2023]
ORDER BY AverageGdpPerCapita Desc





-- Countries from which REGIME TYPE pollute more per capita on average, taking into concideration the population size of each country?
-- Do more democratic countries pollute more on average?

WITH CTE_Co2EmissionsPerCapita AS (
SELECT 
[Free].[Democracy Index 2023] AS RegimeType,
AVG([Co2-Emissions]/Population) as Co2PerCapita,
SUM(Population) AS TotalPopulation
FROM 
[dbo].[Freedom Index] AS Free
INNER JOIN [dbo].[Economy and Info] AS Eco ON Free.Country = Eco.Country
INNER JOIN [dbo].[Population Education Health] AS Pop ON Eco.Country = Pop.Country
GROUP BY [Free].[Democracy Index 2023]
)
SELECT RegimeType,
SUM(Co2PerCapita*TotalPopulation)/SUM(TotalPopulation) AS AverageCo2PerCapita
FROM CTE_Co2EmissionsPerCapita
GROUP BY RegimeType
ORDER BY AverageCo2PerCapita DESC


