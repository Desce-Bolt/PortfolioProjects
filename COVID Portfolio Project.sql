SELECT *
FROM coviddeaths
WHERE continent NOT LIKE ''
ORDER BY 3,4

SELECT *
FROM covidvaccinations
ORDER BY 3,4

-- Select data that it's going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent NOT LIKE ''
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT)/total_cases*100 AS DeathPercentage
FROM coviddeaths
WHERE location LIKE '%Brazil%' and continent NOT LIKE ''
ORDER BY 1,2

-- Looking at Total cases vs Population
-- Shows what percentage of population got covid

SELECT 
	location, 
	date, 
	population, 
	total_cases, 
	CAST(total_cases AS FLOAT)/population*100 AS PercentagePopulationInfected
FROM coviddeaths
--WHERE location LIKE '%Brazil%'
WHERE continent NOT LIKE ''
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population

SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(CAST(total_cases AS FLOAT))/population*100 AS PercentagePopulationInfected
FROM coviddeaths
WHERE continent NOT LIKE '' AND total_cases IS NOT null
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

-- Showing countries with highest death count per population

SELECT 
	location,  
	MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent NOT LIKE '' AND total_deaths IS NOT null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing continents with highest death count per population

SELECT 
	continent,  
	MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
WHERE continent NOT LIKE ''
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
-- Showing DeathPercentage by day

SELECT 
	date, 
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	CAST(SUM(new_deaths) AS FLOAT)/(NULLIF(SUM(new_cases),0))*100 AS DeathPercentage
FROM coviddeaths
WHERE continent NOT LIKE ''
GROUP BY date
ORDER BY 1,2

-- Showing DeathPercentage of all world

SELECT  
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	CAST(SUM(new_deaths) AS FLOAT)/(NULLIF(SUM(new_cases),0))*100 AS DeathPercentage
FROM coviddeaths
WHERE continent NOT LIKE ''
ORDER BY 1,2

-- Looking at total population vs vaccinations
UPDATE covidvaccinations SET new_vaccinations = NULL WHERE new_vaccinations = '';
ALTER TABLE covidvaccinations ALTER COLUMN new_vaccinations TYPE int USING (new_vaccinations::integer);

SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	--RollingPeopleVaccinated/population*100
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent NOT LIKE ''
ORDER BY 2, 3

-- USE CTE 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent NOT LIKE ''
)
SELECT *, (CAST(RollingPeopleVaccinated AS float)/population*100)
FROM PopvsVac

-- TEMP TABLE

DROP TABLE if exists PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
	Continent varchar(255),
	Location varchar(255),
	Date varchar(15),
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated

	SELECT 
		dea.continent, 
		dea.location, 
		dea.date, 
		dea.population, 
		vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM coviddeaths dea
	JOIN covidvaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent NOT LIKE ''

SELECT *, (CAST(RollingPeopleVaccinated AS float)/population*100)
FROM  PercentPopulationVaccinated

-- Creating view to store data for later visualizations

CREATE VIEW "PercentPopulationVaccinated" AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM coviddeaths dea
	JOIN covidvaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent NOT LIKE ''