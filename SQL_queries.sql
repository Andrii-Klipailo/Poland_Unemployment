WITH educatgion_rate AS ( -- checking if somewhere is tertiary_rate more then others
SELECT region
  ,year
  ,ROUND(AVG(tertiary)/AVG(total)*100.0, 1) as tertiary_rate
  ,ROUND(AVG(post_secondary_vocational)/AVG(total)*100.0, 1) as post_secondary_vocational_rate
  ,ROUND(AVG(general_secondary)/AVG(total)*100.0, 1) as general_secondary_rate
  ,ROUND(AVG(basic_vocational)/AVG(total)*100.0, 1) as basic_vocational_rate
  ,ROUND(AVG(primary_lower_secondary)/AVG(total)*100.0, 1) as primary_lower_secondary_rate
FROM `unemployment-463711.unemployment_data.education_data`
GROUP BY 1, 2
)

SELECT *
FROM educatgion_rate
WHERE tertiary_rate > post_secondary_vocational_rate
AND tertiary_rate > general_secondary_rate
AND tertiary_rate > basic_vocational_rate
AND tertiary_rate > primary_lower_secondary_rate
;


-- calculation unemployment_rate
WITH region_unemployed AS(
SELECT region
  ,year
  ,AVG(total) as unemployed
FROM `unemployment-463711.unemployment_data.general_data`
GROUP BY 1, 2
),

poland_unemployed AS(
SELECT year
  ,SUM(unemployed) as unemployed
FROM region_unemployed
GROUP BY 1
),

main_table AS(
SELECT year
  ,unemployed
  ,total
FROM poland_unemployed
JOIN `unemployment-463711.unemployment_data.population_poland`
USING(year)
)

SELECT year
  ,ROUND((unemployed/(total*0.55))*100.0, 1) as unemployment_rate
FROM main_table
ORDER BY year ASC
;


-- Chain-type index
WITH unemployed_table AS(
SELECT year
  ,ROUND(AVG(total), 0) as unemployed
FROM `unemployment-463711.unemployment_data.general_data`
GROUP BY 1
)
SELECT year
  ,ROUND(LEAD(unemployed) OVER(order by year)/unemployed*100.0, 1)
FROM unemployed_table
order by year


-- creating a table with region population and unemployment data
CREATE OR REPLACE TABLE `unemployment-463711.unemployment_data.region_unemployment_and_population` AS 
WITH region_unemployed AS(
SELECT region
  ,year
  ,AVG(total) as unemployed
  ,AVG(men) as unemployed_men
  ,AVG(women) as unemployed_women
  ,AVG(city_residents) as city_residents
  ,AVG(rural_residents) as rural_residents
FROM `unemployment-463711.unemployment_data.general_data`
WHERE year = 2022
GROUP BY region, year
)
SELECT rgn.region
  ,rgn.year
  ,rgn.unemployed
  ,rgn.unemployed_men
  ,rgn.unemployed_women
  ,rgn.city_residents
  ,rgn.rural_residents
  ,ppl.total as population
  ,ppl.men as men_population
  ,ppl.women as women_population
  ,ppl.city_total
  ,ppl.city_men
  ,ppl.city_women
  ,ppl.rural_total
  ,ppl.rural_men
  ,ppl.rural_women
FROM region_unemployed as rgn
JOIN `unemployment-463711.unemployment_data.population_by_region_2022` as ppl
USING(region)
;



-- Chain-type index
WITH unemployed_table AS(
SELECT year
  ,ROUND(AVG(total), 0) as unemployed
FROM `unemployment-463711.unemployment_data.general_data`
GROUP BY 1
)
SELECT year
  ,ROUND(LEAD(unemployed) OVER(order by year)/unemployed*100.0, 1)
FROM unemployed_table
order by year
;


-- unemployment in regions
SELECT region
  ,ROUND((AVG(unemployed)/(AVG(population)*0.55))*100.0, 1) as unemployment_rate
  ,ROUND(AVG(unemployed), 0) as numb_unemployed
  ,ROUND(AVG(unemployed)/(SELECT SUM(unemployed) FROM `unemployment-463711.unemployment_data.region_unemployment_and_population`)*100.0, 1) as part_of_unemployment
FROM `unemployment-463711.unemployment_data.region_unemployment_and_population`
GROUP BY region
ORDER BY unemployment_rate DESC

