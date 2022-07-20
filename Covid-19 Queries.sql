-- Checking all data to begin
SELECT * FROM coviddeaths
ORDER BY 1,2
 
-- Select Data that we are using
SELECT location, DATE , total_cases, new_cases, total_deaths, population 
FROM coviddeaths 
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths (the likelihood of dying if contracting Covid-19 per country. South Africa)
SELECT location, DATE , total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM coviddeaths 
WHERE location LIKE '%South Africa%'
ORDER BY 1,2

-- Looking at Total Cases vs Population  (displays what percentage of population contracted Covid-19. South Africa)
SELECT location, DATE , population, total_cases, (total_cases/population)*100 AS ContractedPercentage
FROM coviddeaths 
WHERE location LIKE '%South Africa%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(cast(total_cases AS SIGNED INT)) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM coviddeaths 
GROUP BY location, population
ORDER BY PercentagePopulationInfected Desc

-- No Null Values are found in the continent column. Update blank values to reflect as "Null"
UPDATE coviddeaths 
SET continent = NULL
WHERE continent = ''

-- Looking at countries with highest Death count per population
SELECT location, MAX(cast(total_deaths AS signed INT)) AS TotalDeathCount
FROM coviddeaths 
WHERE continent IS NOT Null 
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Looking at continents with highest Death count per population
SELECT continent, MAX(cast(total_deaths AS signed INT)) AS TotalDeathCount
FROM coviddeaths 
WHERE continent IS NOT Null 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global new cases vs new deaths
SELECT DATE , SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM coviddeaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Global consensus of cases vs deaths over the entire period since Covid-19 started
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 AS GlobalDeathPercentage
FROM coviddeaths 
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Joining both tables together by location and date
SELECT * 
FROM coviddeaths cd
JOIN covidvaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date

-- Looking at Total Population vs Vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
order BY 2,3



-- With use of a CTE
WITH PopvsVac (continent, location, DATE, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



-- Temp Table creation instead of CTE

DROP TABLE if EXISTS PercentagePopulationVaccinatedT
CREATE TABLE PercentagePopulationVaccinatedT
(
continent VARCHAR(255),
location VARCHAR (255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO PercentagePopulationVaccinatedT
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PercentagePopulationVaccinatedT



-- Creating view to store data for later visualisations
CREATE VIEW PercentagePopulationVaccinatedT AS 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT * FROM PercentagePopulationVaccinatedT
