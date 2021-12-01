select *
from Deaths
where continent is not null
order by 3,4

select *
from Vaccinations
order by 3,4

--select data that we are going to be using
select Location, date, total_cases, new_cases, total_deaths, population
from ProjectPortfolio..Deaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
select location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Deaths
where location like 'Serbia'
order by 1,2

--Looking at highest Country with %CovidPercentage of population
select top 1location, date, population, total_cases, (total_cases/population)*100 as CovidPercentage
from Deaths
where location like 'Serbia'
order by CovidPercentage desc

select location, population,Max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as CovidPercentage
from Deaths
where continent is not null
group by location,population
order by CovidPercentage desc

--Showing Countries with Highest Death Count per Population
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from Deaths
where continent is not null
group by location
order by TotalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT
select continent,Max(cast(total_deaths as int)) as TotalDeathCount
from Deaths
where continent is not null
group by continent
order by TotalDeathCount desc

--Showing continents with the highest death count per populationa
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from Deaths
where continent is null
group by location
order by TotalDeathCount desc

--GLOBAL NUMBERS by date
select date, SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Deaths
where continent is not null
group by date
order by 1,2
--whole world
select SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as Deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Deaths
where continent is not null
--group by date
order by 1,2

--new vaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 1,2,3

--Prikaz novih vakcinisanih po drzavi i ukupna suma od svih vakcinisanih za tu drzavu
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int,v.new_vaccinations)) over (Partition by d.location) as TotalSumOfVacc
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 1,2,3
--Prikaz novih vakcinisanih za drzavu PO DATUMU i ukupna suma(kumulativna suma)
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int,v.new_vaccinations)) over (Partition by d.location Order by d.location,d.date) as CumulativeSumOfVacc
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
order by 1,2,3

--Percent vaccinated people of whole population
select d.continent, d.location, d.date, d.population, v.people_vaccinated, sum(v.people_vaccinated/d.population)*100 AS VaccinatedPercentageOfPopulation
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.people_vaccinated > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.people_vaccinated
order by 1,2,3

-- USE CTE, ili koristiti temp table
With PopVsVac (continent, location, date, population,new_vaccinations, CumulativeSumOfVacc)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int,v.new_vaccinations)) over (Partition by d.location Order by d.location,d.date) as CumulativeSumOfVacc
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
)
--order by 1,2,3
select *, (CumulativeSumOfVacc/population)*100
from PopVsVac

--TEMP TABLE
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
( 
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulativeSumOfVacc numeric
)
insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int,v.new_vaccinations)) over (Partition by d.location Order by d.location,d.date) as CumulativeSumOfVacc
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations

select *, (CumulativeSumOfVacc/population)*100
from #PercentPopulationVaccinated

--Creating View to store data for later visualizations, pernament data

create view PercentPopulationVaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(convert(int,v.new_vaccinations)) over (Partition by d.location Order by d.location,d.date) as CumulativeSumOfVacc
from Deaths d
join Vaccinations v on (d.location = v.location and d.date=v.date)
where d.continent is not null and v.new_vaccinations > 0 and d.location='Serbia'
group by d.continent, d.location, d.date, d.population, v.new_vaccinations
--order by 1,2,3

