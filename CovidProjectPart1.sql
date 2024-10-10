--Select *
--From PortfolioProject1..Deaths$
--Order By 3,4
--2 minute query for 2020-2024 information

--Select *
--From PortfolioProject1..Vaccinations$
--Order By 3,4
--10 second query for 2020-2024 information

--Data of Interest

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject1..Deaths$
Order by 1,2

--Total cases vs Total deaths

Select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as PercentageofMortality
From PortfolioProject1..Deaths$
Order by 1,2

--Specifying Location

Select location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as PercentageofMortality
From PortfolioProject1..Deaths$
Where location like '%states%'
Order by 1,2 

--Total cases vs. Population
Select location, date, total_cases, population, (total_cases/population) * 100 as ContagionRate
From PortfolioProject1..Deaths$
Where location like '%states%'
Order by 1,2 

--Comparing Infected population to ContagionRate at Peak Across All Countries (View US, UK vs England, Incomebased Groups, Continents)
Select location, population, MAX(total_cases) as PeakInfectionCounter, MAX((total_cases/population)) * 100 as PeakContagionRate
From PortfolioProject1..Deaths$
--Continent grouping are in data set, not useful in context
WHERE continent is not null
--Aggregate is needed, group function is used
Group by Location, Population
Order by PeakContagionRate DESC 

--Deaths compared across all countries
Select location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject1..Deaths$
--Continent grouping are in data set, not useful in context
WHERE continent is not null
--Aggregate is needed, group function is used
Group by Location
Order by TotalDeathCount DESC 

--Deaths compared across all continents
Select continent, MAX(total_deaths) as TotalDeathCount
From PortfolioProject1..Deaths$
--Continent grouping are in data set
WHERE continent is not null
--Aggregate is needed, group function is used
Group by continent
Order by TotalDeathCount DESC 

--Deaths across all groupings in data set (Accurate)
Select location, MAX(total_deaths) as TotalDeathCount
From PortfolioProject1..Deaths$
--Continent grouping & Income grouping are in data set
WHERE continent is null
--Aggregate is needed, group function is used
Group by location
Order by TotalDeathCount DESC






-- Global Statistics Weekly

Select Date, Sum(new_cases) as TotalCases, Sum(Cast(new_deaths as int)) as TotalDeaths, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as MortalityRate
-- New Deaths are wrong data type, cast changes temporarily for query
From PortfolioProject1..Deaths$
Where continent is not null AND new_cases <> 0 AND new_deaths <> 0 --removes error calculations as new cases and new deaths reported weekly
Group By Date
Order By 1,2



-- Total Population versus Vaccionated Population
Select DTH.continent, DTH.location, DTH.date, DTH.population, VAC.new_vaccinations
-- convert = cast in methodology, bigint to fit all sigfigs, rows unbounded preceding means window function starts at first row of partition like a lower bound
, SUM(convert(bigint, VAC.new_vaccinations)) OVER (Partition by DTH.location Order by DTH.location, DTH.date ROWS UNBOUNDED PRECEDING) as RollingCountVaccinations
--, (RollingCountVaccinations/population)*100
FROM PortfolioProject1..Deaths$ DTH
Join PortfolioProject1..Vaccinations$ VAC
	On DTH.location = VAC.location
	AND DTH.date = VAC.date
Where DTH.continent is not null
Order by 2,3


-- Using CTE to run percent of vaccinated

With PopulationvsVac (Continent, Location, Date, Population, new_vaccinations, RollingCountVaccinated)
as
(
Select DTH.continent, DTH.location, DTH.date, DTH.population, VAC.new_vaccinations
-- convert = cast in methodology, bigint to fit all sigfigs, rows unbounded preceding means window function starts at first row of partition like a lower bound
, SUM(convert(bigint, VAC.new_vaccinations)) OVER (Partition by DTH.location Order by DTH.location, DTH.date ROWS UNBOUNDED PRECEDING) as RollingCountVaccinated
--, (RollingCountVaccinations/population)*100
FROM PortfolioProject1..Deaths$ DTH
Join PortfolioProject1..Vaccinations$ VAC
	On DTH.location = VAC.location
	AND DTH.date = VAC.date
Where DTH.continent is not null
--Order by 2,3
)
Select *, (RollingCountVaccinated/population)*100
From PopulationvsVac

--Rates higher than 100% can be attributed to dosing regimen, vaccination requirments for travelers, population rate of change not accounted for, etc

--Temp Table Version

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
New_vaccinations int,
RollingCountVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select DTH.continent, DTH.location, DTH.date, DTH.population, VAC.new_vaccinations
-- convert = cast in methodology, bigint to fit all sigfigs, rows unbounded preceding means window function starts at first row of partition like a lower bound
, SUM(convert(bigint, VAC.new_vaccinations)) OVER (Partition by DTH.location Order by DTH.location, DTH.date ROWS UNBOUNDED PRECEDING) as RollingCountVaccinated
--, (RollingCountVaccinations/population)*100
FROM PortfolioProject1..Deaths$ DTH
Join PortfolioProject1..Vaccinations$ VAC
	On DTH.location = VAC.location
	AND DTH.date = VAC.date
Where DTH.continent is not null
--Order by 2,3

Select *, (RollingCountVaccinated/population)*100
From #PercentPopulationVaccinated

--Creating View to store data for later visualization

Create View PercentPopulationVaccinated as
Select DTH.continent, DTH.location, DTH.date, DTH.population, VAC.new_vaccinations, SUM(convert(bigint, VAC.new_vaccinations)) OVER (Partition by DTH.location Order by DTH.location, 
DTH.date ROWS UNBOUNDED PRECEDING) as RollingCountVaccinated
--, (RollingCountVaccinations/population)*100 requires temp table/CTE
FROM PortfolioProject1..Deaths$ DTH
Join PortfolioProject1..Vaccinations$ VAC
	On DTH.location = VAC.location
	AND DTH.date = VAC.date
Where DTH.continent is not null


Select *, (RollingCountVaccinated/population)*100
From PercentPopulationVaccinated