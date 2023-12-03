-- 1. Finding out the percentage of Active(not recruiting), Recruiting, Completed, Terminated, Withdrawn trials etc to the total.
select sub1.overall_status, trials_count, round((cast(sub1.trials_count as decimal) / sub3.total)*100,2) as pct_of_total
from 
   -- Cross joining trials_count grouped by overall_status with total count of trials
     (select s.overall_status, count(distinct s.nct_id) as trials_count
      from ctgov.studies as s
      inner join ctgov.conditions as c 
	        on s.nct_id = c.nct_id
      where lower(c.name) like '%cancer%'
      group by s.overall_status) as sub1
      cross join 
	           -- Total count of trials
	             (select sum(trials_count) as total
                  from 
			   -- Trials count grouped by overall_status
				  (select s.overall_status, count(distinct s.nct_id) as trials_count
                        from ctgov.studies as s
                        inner join ctgov.conditions as c 
					          on s.nct_id = c.nct_id
                        where lower(c.name) like '%cancer%'
                        group by s.overall_status) as sub2) as sub3
order by pct_of_total desc
	

-- 2. Creating a view for completed cancer-related clinical trials, detailing NCT ID, condition, inclusion/exclusion criteria, trial location, intervention, and total participants.
create or replace view cancer_trials_view
as
select sub1.nct_id, sub1.condition,
       sub2.overall_status, sub2.total_participants,
       e.criteria,
       f.city, f.state, f.country,
       i.intervention_type, i.name as intervention
-- Subset for cancer trials is selected at this step to reduce query times
from (select c.nct_id, c.name as condition
      from ctgov.conditions as c
      where c.name ilike'%cancer%') as sub1
-- Subset for cancer trials which are completed are selected at this step to reduce query times
inner join (select s.nct_id,
             s.overall_status,
             s.enrollment as total_participants
            from ctgov.studies as s
            where s.overall_status = 'Completed') as sub2 
      on sub1.nct_id = sub2.nct_id
-- Left joins are used since we want all the trials from the above subsets even if they do not have any data in the other tables
left join ctgov.eligibilities as e on sub1.nct_id = e.nct_id
left join ctgov.facilities as f on sub1.nct_id = f.nct_id
left join ctgov.interventions as i on sub1.nct_id = i.nct_id
	

-- 3. Analyzing the phase-wise distribution of completed cancer trials.
select s.phase, count(distinct s.nct_id) as trials_count
from ctgov.studies as s
inner join ctgov.conditions as c 
	  on s.nct_id = c.nct_id
where s.nct_id in (select distinct nct_id 
		   from cancer_trials_view)
-- Eliminating rows where phase data is 'Not Available' or null
and s.phase not like '%Not%' and s.phase is not null
group by s.phase


-- 4. Creating a view for all observed adverse events and outcomes recorded for each completed trial.
create view cancer_trials_adverse_events as
select * from ctgov.reported_events
where nct_id in (select distinct ct.nct_id 
		 from cancer_trials_view as ct)


-- 5. Finding out which organ system is most commonly affected as a result of adverse effects for each intervention type.
-- Ranking organ systems based on descending trial count, partitioned by intervention type from adverse effects view
with tbl1 as
(select i.intervention_type, organ_system, count(distinct ctae.nct_id) as trials_count, 
       row_number() over(partition by i.intervention_type order by count(distinct ctae.nct_id) desc) as rank
from cancer_trials_adverse_events as ctae
inner join ctgov.interventions as i
      on ctae.nct_id = i.nct_id
group by intervention_type, organ_system
order by intervention_type asc, trials_count desc)
-- Selecting the organ_system with the most number of adverse effects for each intervention type
select tbl1.intervention_type, tbl1.organ_system
from tbl1
where rank = 1
group by intervention_type, organ_system
order by intervention_type asc


-- 6. Finding out the top 10 trials that had the most patients with a complete response to the intervention of study.
select distinct s.nct_id, source, start_date, completion_date, study_type, official_title, category_ranking
from ctgov.studies as s
inner join (select o.nct_id, o.category, count(*) as category_ranking
	    from ctgov.outcome_measurements as o
	    where o.nct_id in (select distinct ct.nct_id
			       from cancer_trials_view as ct)
			       group by o.nct_id, o.category 
                               -- Selecting trials having complete response
			       having lower(o.category) like '%complete response%' 
                               -- Eliminating categories such as no complete response, incomplete response, unconfirmed complete response etc.
                               and lower(o.category) not like '%no%' 
	                       and lower(o.category) not like '%incomplete%'
	                       and lower(o.category) not like '%unconfirmed%'
	                       and lower(o.category) not like '%w/out%'
			       order by category_ranking desc
	                       -- Selecting the top 10 trials 
			       limit 10) as sub
      on s.nct_id = sub.nct_id
order by category_ranking desc


-- 7. Analyzing the distribution of trials by state. 
select state, country, count(distinct nct_id) as statewise_number_of_trials
from cancer_trials_view
where state is not null
group by state, country
order by statewise_number_of_trials desc


-- 8. Creating a view to identify trials conducted at multiple facilities.
create view multi_facility_trials as
select nct_id, count(id) as facility_count from ctgov.facilities
where nct_id in (select distinct nct_id
	         from cancer_trials_view)
group by nct_id
having count(id) > 1
order by facility_count desc


-- 9. Finding out the number of trials that started after 2018 and were completed before 2023.
select count(*) as number_of_trials
from (select distinct s.nct_id, s.start_date, s.completion_date, s.source, s.official_title
from ctgov.studies as s
where s.nct_id in (select distinct ct.nct_id
				   from public.cancer_trials_view as ct)
and extract(year from s.start_date) > 2018 and extract (year from s.completion_date) < 2023)


-- 10. Comparing the number of cancer trials started and completed within 5 years, countrywise over a period of the last 15 years.
-- Trials that started between 2018 and completed before 2023
with tbl1 as 
(select ct.country, count(distinct ct.nct_id) as trials_count
from cancer_trials_view as ct
inner join ctgov.studies as s
      on ct.nct_id = s.nct_id
where extract(year from s.start_date) >= 2018 and extract(year from s.completion_date) <= 2023
group by ct.country
order by trials_count desc),
-- Trials that started between 2012 and completed before 2017
tbl2 as
(select ct.country, count(distinct ct.nct_id) as trials_count
from cancer_trials_view as ct
inner join ctgov.studies as s
      on ct.nct_id = s.nct_id
where extract(year from s.start_date) >= 2012 and extract(year from s.completion_date) <= 2017
group by ct.country
order by trials_count desc),
-- Trials that started between 2006 and completed before 2011
tbl3 as
(select ct.country, count(distinct ct.nct_id) as trials_count
from cancer_trials_view as ct
inner join ctgov.studies as s
      on ct.nct_id = s.nct_id
where extract(year from s.start_date) >= 2006 and extract(year from s.completion_date) <= 2011
group by ct.country
order by trials_count desc)
select tbl1.country, tbl1.trials_count as trials_between_2018_2023, 
	   tbl2.country, tbl2.trials_count as trials_between_2012_2017,
	   tbl3.country, tbl3.trials_count as trials_betwwen_2006_2011
from tbl1
full outer join tbl2 
     on tbl1.country = tbl2.country
full outer join tbl3
     on tbl1.country = tbl3.country


-- 11. Finding the average number of months taken by countries to complete cancer related trials and draw a comparison between them.
select distinct ct.country, count(distinct ct.nct_id) as count_of_trials_conducted,
	                      -- Finding date difference in years, multiplying it by 12 to convert to months
		round(cast(avg((date_part('year', s.completion_date::date) - date_part('year', s.start_date::date))*12 +
	                      -- Adding difference in months to the above
	                       (date_part('month', s.completion_date::date) - date_part('month', s.start_date::date))) as numeric),2) as avg_months_to_complete
from ctgov.studies as s
inner join public.cancer_trials_view as ct
      on s.nct_id = ct.nct_id
where (date_part('year', s.completion_date::date) - date_part('year', s.start_date::date))*12 +
      (date_part('month', s.completion_date::date) - date_part('month', s.start_date::date)) > 0
group by ct.country
-- Removing countries having low trial counts since these would be outliers
having count(distinct ct.nct_id) >= 100
order by count_of_trials_conducted desc, avg_months_to_complete asc


-- 12. Analyzing the correlation between the type of intervention and the duration of completed trials.
select i.intervention_type, count(distinct i.nct_id) as count_of_trials_conducted,
       -- Avg months to complete using date_part
       round(cast(avg((date_part('year', s.completion_date::date) - date_part('year', s.start_date::date))*12 +
	                  (date_part('month', s.completion_date::date) - date_part('month', s.start_date::date))) as numeric),2) as avg_months_to_complete
from ctgov.interventions as i
inner join ctgov.studies as s
      on i.nct_id = s.nct_id
where i.nct_id in (select distinct nct_id
				   from public.cancer_trials_view)
group by i.intervention_type
order by avg_months_to_complete desc


