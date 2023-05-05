--DATA CLEANING
-- convert all dates to Date
UPDATE intakes SET i_date = CONVERT(Date, i_date)
SELECT ID, i_date from intakes

UPDATE outcomes SET o_date = CONVERT(Date, o_date)
SELECT ID, o_date from outcomes

UPDATE outcomes SET birth_date = CONVERT(Date, birth_date)
SELECT ID, birth_date from outcomes

-- check and remove duplicates 
-- FOR INTAKES:

--with RowNumCTE as(
--	SELECT *,
--		ROW_NUMBER() OVER(
--			PARTITION BY ID, i_date
--			ORDER BY ID) row_num
--	FROM intakes)

--SELECT * FROM RowNumCTE
--WHERE row_num > 1
--ORDER BY ID

--DELETE FROM RowNumCTE
--WHERE row_num > 1

-- FOR OUTCOMES:
with RowNumCTE as(
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY ID, o_date
			ORDER BY ID) row_num
	FROM outcomes)

SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY ID

--DELETE FROM RowNumCTE
--WHERE row_num > 1


-- see unique values for columns that matter for analysis, change nulls to unknowns in the proper columns
SELECT DISTINCT intake_type FROM intakes
SELECT DISTINCT condition FROM intakes
SELECT DISTINCT animal_type FROM intakes
SELECT DISTINCT i_sex FROM intakes -- 'NULL' found, change it to 'Unknown'

SELECT DISTINCT outcome_type from outcomes -- one is empty, change it to 'Non-specified'
SELECT DISTINCT animal_type from outcomes
SELECT DISTINCT o_sex from outcomes -- 'NULL' found, change it to 'Unknown'

-- Make the changes
--UPDATE outcomes SET outcome_type = 'Non-specified' WHERE outcome_type = ''
--UPDATE outcomes SET o_sex = 'Unknown' WHERE o_sex = 'NULL'
--UPDATE intakes SET i_sex = 'Unknown' WHERE i_sex = 'NULL'

-- DATA ANALYSIS

-- INTAKES
-- months when the shelter has more intakes
SELECT MONTH(i_date) as i_month, COUNT(*) as nr_intakes FROM intakes
GROUP BY MONTH(i_date)
ORDER BY MONTH(i_date)

-- what animal type has the most intakes?
SELECT animal_type, count(*) as nr_intakes FROM intakes
GROUP BY animal_type
ORDER BY count(*) DESC

-- counting the ammount of animals intakes for each year (did it decrease or increase?)
SELECT year(i_date) as i_year, COUNT(*) as nr_intakes FROM intakes
GROUP BY year(i_date)
ORDER BY year(i_date)

-- What intake_type is most common?
SELECT intake_type, COUNT(*) as nr_intakes FROM intakes
GROUP BY intake_type
ORDER BY COUNT(*) DESC


-- INTAKES VS OUTCOMES
-- for how long did the animals were at the shelter before getting adopted (only the ones who were adopted)
with adoptiontimeCTE as (
SELECT i.id, i.animal_type, DATEDIFF(day, i.i_date, o.o_date) as days_in_shelter FROM intakes i
JOIN outcomes o
ON i.id = o.id
WHERE o.outcome_type = 'Adoption')

-- because the data begins only from 2013, it's possible other animals entered & left the shelter before that, and came back, therefore making the datediff between i_date and o_date be a negative number.
-- To overcome that, we take those animals out of the calculations (1704 out of 49538 adopted animals)
SELECT DISTINCT ID, animal_type, SUM(days_in_shelter) OVER (PARTITION BY (ID)) as total_days FROM adoptiontimeCTE
--WHERE days_in_shelter >= 0
ORDER BY total_days

-- Now, the average of days in shelter per animal type
SELECT DISTINCT animal_type, AVG(days_in_shelter) OVER (PARTITION BY (animal_type)) as avg_days FROM adoptiontimeCTE
WHERE days_in_shelter >= 0
ORDER BY avg_days

--OUTCOMES
-- Most common type of outcome
SELECT outcome_type, count(*) FROM outcomes
GROUP BY outcome_type
ORDER BY count(*) DESC

-- what ages are most common for animals to get adopted?
with ageCTE as (
SELECT ID, DATEDIFF(year, birth_date, o_date) as age_year FROM outcomes
WHERE outcome_type = 'Adoption')

SELECT age_year, COUNT(*) as nr_adoptions FROM ageCTE
GROUP BY age_year
ORDER BY age_year ASC


-- most common animal type to get adopted?
SELECT animal_type, COUNT(*) as count FROM outcomes
GROUP BY animal_type, outcome_type
HAVING outcome_type = 'Adoption'
ORDER BY COUNT(*) DESC

-- for any outcome type, how many animals were neutered/spayed and how many were intact?
with sexCTE as (SELECT distinct id, animal_type, 
	CASE
		WHEN o_sex = 'Intact Male' THEN 'Intact'
		WHEN o_sex = 'Intact Female' THEN 'Intact'
		WHEN o_sex = 'Spayed Female' THEN 'Spayed/Neutered'
		WHEN o_sex = 'Neutered Male' THEN 'Spayed/Neutered'
		ELSE 'Unknown'
	END as sex_detail
FROM outcomes
-- WHERE outcome_type = 'Adoption'  -- we can filter by the outcome type, to see how it differs from the general analysis.
)

SELECT sex_detail, COUNT(*) as nr_animals FROM sexCTE
GROUP BY sex_detail
ORDER BY COUNT(*) DESC
