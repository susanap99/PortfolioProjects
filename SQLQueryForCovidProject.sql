SELECT * FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Selecting the data, BY LOCATION

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total cases vs. Total deaths (Portugal), likelihood of dying if you have Covid in Portugal
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location = 'Portugal'
ORDER BY 1,2


-- Total Cases vs. Population, percentage of population got Covid
SELECT Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Countries with highest infection rate compared to population
SELECT Location, population, Max(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM CovidPortfolioProject..CovidDeaths
GROUP BY Location, population
ORDER BY 4 DESC

--Countries with highest Death Count per Population
SELECT Location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC

-- BY CONTINENT
--Assuming that the data on excel is not well organized (so, in continent there's only continents and in location only country names)
----SELECT location, MAX(CAST(total_deaths as INT)) as TotalDeathCount
----FROM CovidPortfolioProject..CovidDeaths
----WHERE continent IS NULL
----GROUP BY location
----ORDER BY 2 DESC

--The other way (since the data is not well organized)
-- Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths as INT)) as TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

--Global numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Total Population vs Vaccinations

--SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
--SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingCountPeopleVaccinated,
--(RollingCountPeopleVaccinated/population)*100
--FROM CovidPortfolioProject..CovidDeaths d
--JOIN CovidPortfolioProject..CovidVaccinations v
--	ON d.location = v.location AND  d.date = v.date
--WHERE d.continent IS NOT NULL
--ORDER BY 2, 3

--using CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingCountPeopleVaccinated)
as
(SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingCountPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths d
JOIN CovidPortfolioProject..CovidVaccinations v
	ON d.location = v.location AND  d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT *, (RollingCountPeopleVaccinated/population)*100 as RollingCountPercentageVaccinated FROM PopvsVac

--using TEMP table

DROP table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingCountPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingCountPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths d
JOIN CovidPortfolioProject..CovidVaccinations v
	ON d.location = v.location AND  d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, (RollingCountPeopleVaccinated/population)*100 as RollingCountPercentageVaccinated
FROM #PercentPopulationVaccinated



-- CREATE A VIEW TO STORE THE DATA FOR LATER VISUALIZATIONS

CREATE VIEW RollingCountPplVaccinated as
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as RollingCountPeopleVaccinated
FROM CovidPortfolioProject..CovidDeaths d
JOIN CovidPortfolioProject..CovidVaccinations v
	ON d.location = v.location AND  d.date = v.date
WHERE d.continent IS NOT NULL

SELECT * FROM RollingCountPplVaccinated