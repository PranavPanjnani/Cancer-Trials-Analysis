-- Task 2
-- Create a view for all observed adverse events and outcomes recorded for each trial.

create view cancer_trials_adverse_events as
select * from ctgov.reported_events
where nct_id in (select distinct ct.nct_id 
				 from public.cancer_trials_view as ct)