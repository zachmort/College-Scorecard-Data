
/*Checking all of the tables are in*/
SELECT * FROM Sys.objects WHERE Type='u'


/*checking data in each table*/
select top 5 *
from school..academics_college_data$

select top 5 *
from school..admissions_college_data$

select top 5 *
from school..aid_college_data$

select top 5 *
from school..completion_college_data$

select top 5 *
from school..cost_college_data$

select top 5 *
from school..repayment_college_data$

select top 5 *
from school..school_college_data$

select top 5 *
from school..student_college_data$
/*All data looks good*/

/*---------------------------------------------Questions and Queries---------------------------------------------*/

/*Looking at the college I went to!*/
SELECT * From school..school_college_data$ WHERE INSTNM LIKE 'Bentley%'

/*Avg income after graduation from Bentley*/
select INSTNM, MD_EARN_WNE_P10
from school..school_college_data$ as school
join school..earnings_college_data$ as earn
on earn.UNITID = school.UNITID
where INSTNM like 'Bentley%'
order by MD_EARN_WNE_P10 DESC


/*What school has the largest Enrollment of undergraduate certificate/degree-seeking students UGDS*/
select INSTNM, UGDS
from school..student_college_data$ as stud
join school..school_college_data$ as school
on school.UNITID = stud.UNITID
order by UGDS DESC


/*---------------------------------------------Looking at most expensive schools---------------------------------------------*/

/*looks like field COSTT4_P is a navchar(22) type need to convert this*/
/*Setting the null character columns to 0 because you can convert string nulls to ints*/
update school..cost_college_data$ set COSTT4_P = 0 where COSTT4_P is null
/*Now convert to an float*/
alter table school..cost_college_data$ alter column COSTT4_P int;
/*Replacing 0 values with NULL*/
update school..cost_college_data$ set COSTT4_P = NULL where COSTT4_P = 0

/*adding a combined column for COSTT4_P and COSTT4_A, Both of these are  average costs for all aspects of schooling for acadmeic year and program schools*/
/*creating a temp table for the sum of both costs without the null values*/
drop table if exists #costcombinedtable

select cost.UNITID as UNITID, INSTNM as INSTNM , sum(isnull(COSTT4_P, 0) + isnull(COSTT4_A,0)) as COSTT4_combined into #costcombinedtable
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on cost.UNITID = school.UNITID
group by cost.UNITID, INSTNM

/*checking that the temp table was created*/
select *
from #costcombinedtable
order by COSTT4_combined DESC

/*making the 0 dollar rows in COSTT4_combined to NULL values*/
update #costcombinedtable set COSTT4_combined = null where COSTT4_combined = 0

/*checking that the temp table was updated properly*/
select *
from #costcombinedtable
order by COSTT4_combined DESC

/*program year schools
select INSTNM, COSTT4_P
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on school.UNITID = cost.UNITID
/*where COSTT4_P is not null*/
order by COSTT4_P DESC*/

/*academic year schools
select INSTNM, COSTT4_A as int
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on school.UNITID = cost.UNITID
where COSTT4_A is not null
order by COSTT4_A DESC*/


/*---------------------------------------------What is the average price of school in each state---------------------------------------------
broken out public, private and non for profit, and ranked*/
select 
	STABBR as state_abrev,
	Case
		when CONTROL = 1 then 'Public'
		when CONTROL = 2 then 'Private for profit'
		when CONTROL = 3 then 'Private Non for profit'
		end as Institution_Type,
		round(avg(COSTT4_combined),2) as average_cost,
		row_number() over (partition by STABBR order by round(avg(COSTT4_combined), 2) DESC) as Rank
from 
	school..cost_college_data$ as cost
	join school..school_college_data$ as school
on school.UNITID = cost.UNITID
	join #costcombinedtable as combined
on cost.UNITID = combined.UNITID
group by STABBR, CONTROL
order by STABBR, Institution_Type


/*---------------------------------------------earnings after graduation per school---------------------------------------------*/
select INSTNM as institution_name, MD_EARN_WNE_P10 as median_earnings_10yr_after_grad
from school..school_college_data$ as school
join school..earnings_college_data$ as earn
on earn.UNITID = school.UNITID
order by MD_EARN_WNE_P10 DESC


/*---------------------------------------------number of programs offered---------------------------------------------
Diversity of schools academics*/
select INSTNM, PRGMOFR/*, avg(PRGMOFR) , max(PRGMOFR)/avg(PRGMOFR)*/
from school..academics_college_data$ as aca
join school..school_college_data$ as school
on school.UNITID = aca.UNITID
order by PRGMOFR DESC

/*running total of NET TUTITION REVENUE VS TUITION EXPENDATURE PER STUDENT(includes graduate students) from all schools AND use a row that is the percentage of each amount relative to the total*/
select 
	INSTNM as Institution_name,
	TUITFTE as Net_tuition, 
	INEXPFTE as Tuition_expendature, 
	round(sum(TUITFTE) over (order by TUITFTE DESC), 2) as running_revenue_total_all_schools
from 
	school..cost_college_data$ as cost
	join school..school_college_data$ as school
on cost.UNITID = school.UNITID
where TUITFTE is not null

/*look at avg INEXPFTE vs TUITFTE per different controls of school*/
select 
	CONTROL,
		case 
		when control = 1 then 'Public'
		when control = 2 then 'Private Nonprofit'
		when control = 3 then 'Private for-profit'
		end as Institution_control,
		round(avg(TUITFTE),2) as avg_revenue, 
		round(avg(INEXPFTE), 2) as avg_expenses,
	    (avg(TUITFTE) - avg(INEXPFTE)) as avg_net_profit
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on cost.UNITID = school.UNITID
group by CONTROL
order by CONTROL


/*---------------------------------------------biggest decrese in tuition from out of state to instate---------------------------------------------*/
drop table if exists tuitiontable

With tuitiontable as (
select 
	STABBR as state_abriv,
	avg(TUITIONFEE_OUT) as out_state_tuition,
	avg(TUITIONFEE_IN) as in_state_tuition,
	1-coalesce(avg(TUITIONFEE_IN) / avg(TUITIONFEE_OUT), 0) as percent_discount_in_tuition
from 
	school..cost_college_data$ as cost
	join school..school_college_data$ as school
on school.UNITID = cost.UNITID
group by STABBR
)select 
	state_abriv,
	out_state_tuition,
	in_state_tuition,
	percent_discount_in_tuition,
	row_number() over (order by percent_discount_in_tuition) as biggest_discount_state
from tuitiontable
order by state_abriv


/*---------------------------------------------Admin rates and SAT_AVG do these have a correlation to the type of control of a given school?---------------------------------------------*/
select 
	INSTNM as Institution_name,
	SAT_AVG as SAT_average_score, 
	ADM_RATE as admin_rate
from 
	school..school_college_data$ as school
	join school..admissions_college_data$ as admin
on school.UNITID = admin.UNITID
where 
	ADM_RATE is not null 
	and SAT_AVG is not null
order by ADM_RATE DESC

/*---------------------------------------------avg admin rate and sat_score for each type of school control---------------------------------------------*/
select 
	control,
	case 
		when control = 1 then 'Public'
		when control = 2 then 'Private Nonprofit'
		when control = 3 then 'Private for-profit'
		end as Institution_control,
	avg(SAT_AVG)as avg_sat_score, 
	avg(ADM_RATE) as avg_admin_rate
from school..school_college_data$ as school
join school..admissions_college_data$ as admin
on school.UNITID = admin.UNITID
group by control
order by control

/*---------------------------------------------Repayment rates for completers and non completers---------------------------------------------*/
select 
	avg(COMPL_RPY_1YR_RT) as completor_repayment_rate, 
	avg(NONCOM_RPY_1YR_RT) as non_completor_repayment_rate
from school..repayment_college_data$

/*---------------------------------------------total debt from all schools---------------------------------------------*/
select 
	INSTNM as Institution_name, 
	GRAD_DEBT_MDN as Median_grad_debt, 
	sum(GRAD_DEBT_MDN) over (order by INSTNM DESC) as running_total_debt
from 
	school..aid_college_data$ as aid
	join school..school_college_data$ as school
on aid.UNITID = school.UNITID
where GRAD_DEBT_MDN is not null
group by 
	INSTNM, 
	GRAD_DEBT_MDN

/*---------------------------------------------Running debt and % by state---------------------------------------------*/
with state_debt as
(
select 
	STABBR as state_abbreviation, 
	sum(GRAD_DEBT_MDN) as student_debt
from 
	school..aid_college_data$ as aid
	join school..school_college_data$ as school
on aid.UNITID = school.UNITID
where GRAD_DEBT_MDN is not null
group by STABBR
/*order by STABBR*/
) Select 
	state_abbreviation, 
	student_debt, 
	sum(student_debt) over (order by student_debt)/ sum(student_debt) over () as cumulative_percent
from state_debt
order by cumulative_percent



/*---------------------------------------------student grad rates based on if they are a minority population in the school---------------------------------------------*/
with race_grad_percentage as
(
select
	UGDS_WHITE,
	UGDS_BLACK,
	UGDS_HISP ,
	UGDS_ASIAN,
	UGDS_AIAN ,
	case 
	when UGDS_WHITE > .3 then 'Majority White'
	when UGDS_BLACK > .3 then 'Majority Black'
	when UGDS_HISP > .3 then 'Majority Hispanic'
	when UGDS_ASIAN > .3 then 'Majority Asian'
	when UGDS_AIAN > .3 then 'Majority Indian'
	end as stud_bod_percent
from school..completion_college_data$ as school
join school..student_college_data$ as stud
on school.UNITID = stud.UNITID
where UGDS_WHITE is not null
)select stud_bod_percent,count(stud_bod_percent) as number_of_schools
from race_grad_percentage
where stud_bod_percent is not null
group by stud_bod_percent
order by number_of_schools


/*---------------------------------------------Looking at graduation rate based on different college ethnicity %---------------------------------------------*/
drop table if exists #school_demographics


select
	stud.UNITID,
	INSTNM,
	UGDS_WHITE,
	UGDS_BLACK,
	UGDS_HISP ,
	UGDS_ASIAN,
	UGDS_AIAN ,
	case 
	when UGDS_WHITE > .3 then 'Majority White'
	when UGDS_BLACK > .3 then 'Majority Black'
	when UGDS_HISP > .3 then 'Majority Hispanic'
	when UGDS_ASIAN > .3 then 'Majority Asian'
	when UGDS_AIAN > .3 then 'Majority Indian'
	else 'Balanced'
	end as stud_bod_percent
into #school_demographics
from school..completion_college_data$ as completion
join school..student_college_data$ as stud
on completion.UNITID = stud.UNITID
join school..school_college_data$ as school
on school.UNITID = stud.UNITID
where UGDS_WHITE is not null

/*---------------------------------------------Checking out how caucasian ethnicity grad rate changes based on school ethnicity &---------------------------------------------*/
select avg(UGDS_WHITE) as white_grad_percent, stud_bod_percent
from #school_demographics
group by stud_bod_percent

select avg(UGDS_BLACK) as black_grad_percent, stud_bod_percent
from #school_demographics
group by stud_bod_percent

select avg(UGDS_AIAN) as indian_grad_percent, stud_bod_percent
from #school_demographics
group by stud_bod_percent

select avg(UGDS_HISP) as hispanic_grad_percent, stud_bod_percent
from #school_demographics
group by stud_bod_percent

select avg(UGDS_ASIAN) as asian_grad_percent, stud_bod_percent
from #school_demographics
group by stud_bod_percent
