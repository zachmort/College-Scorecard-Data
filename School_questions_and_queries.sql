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


/*Looking at most expensive schools*/

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


/*What is the average price of school in each state
broken out public, private and non for profit, and ranked*/
/*make sure each case  statement is correct*/
select STABBR as state_abrev,
		Case
			when CONTROL = 1 then 'Public'
			when CONTROL = 2 then 'Private for profit'
			when CONTROL = 3 then 'Private Non for profit'
		end as Institution_Type,
		avg(COSTT4_combined) as average_cost,
		row_number() over (partition by STABBR order by round(avg(COSTT4_combined), 2) DESC) as Rank
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on school.UNITID = cost.UNITID
join #costcombinedtable as combined
on cost.UNITID = combined.UNITID
group by STABBR, CONTROL
order by STABBR, Institution_Type


/*earnings after graduation per school*/
select INSTNM, MD_EARN_WNE_P10
from school..school_college_data$ as school
join school..earnings_college_data$ as earn
on earn.UNITID = school.UNITID
order by MD_EARN_WNE_P10 DESC


/*most expensive schools
do the most expensive schools take the longest to pay off
2 cte 1 win above avg tuition 1 with below avg tuition and then look at average pay off time for each one*/
select
from school..cost_college_data$




/*number of programs offered vs avg and plot % increase for each school
Diversity of schools academics*/
/*this column is a varchar needs to be changed to a */
select INSTNM, PRGMOFR/*, avg(PRGMOFR) , max(PRGMOFR)/avg(PRGMOFR)*/
from school..academics_college_data$ as aca
join school..school_college_data$ as school
on school.UNITID = aca.UNITID
order by PRGMOFR DESC

/*running total of NET TUTITION REVENUE VS TUITION EXPENDATURE PER STUDENT(includes graduate students) from all schools AND use a row that is the percentage of each amount relative to the total*/
select INSTNM,TUITFTE, INEXPFTE, avg(TUITFTE) over (order by TUITFTE DESC) as running_revenue_total_all_schools
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on cost.UNITID = school.UNITID
where TUITFTE is not null

/*look at avg INEXPFTE vs TUITFTE per different controls of school*/
select CONTROL, round(avg(TUITFTE),2) as avg_revenue, round(avg(INEXPFTE), 2) as avg_expenses, (avg(TUITFTE) - avg(INEXPFTE)) as avg_net_profit
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on cost.UNITID = school.UNITID
group by CONTROL
order by CONTROL



/*total debt out standing per race class in each state*/
select
round(avg(C150_4_WHITE),2) as graduation_rate_White,
round(avg(C150_4_BLACK),2) as graduation_rate_Black,
round(avg(C150_4_HISP), 2) as graduation_rate_Hispanic,
round(avg(C150_4_ASIAN), 2) as graduation_rate_Asian,
round(avg(C150_4_AIAN), 2) as graduation_rate_American_Indian
from school..completion_college_data$


/*biggest decrese in tuition from out of state to instate*/
drop table if exists tuitiontable

With tuitiontable as (
select STABBR as state_abriv,
avg(TUITIONFEE_OUT) as out_state_tuition,
avg(TUITIONFEE_IN) as in_state_tuition,
coalesce(avg(TUITIONFEE_IN) / avg(TUITIONFEE_OUT), 0) as percent_difference_in_tuition
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on school.UNITID = cost.UNITID
group by STABBR
)select state_abriv,
out_state_tuition,
in_state_tuition,
percent_difference_in_tuition,
row_number() over (order by percent_difference_in_tuition) as biggest_discount_state
from tuitiontable
order by state_abriv

/*avg graduation rates per race class for total population*/
select
round(avg(C150_4_WHITE),2) as graduation_rate_White,
round(avg(C150_4_BLACK),2) as graduation_rate_Black,
round(avg(C150_4_HISP), 2) as graduation_rate_Hispanic,
round(avg(C150_4_ASIAN), 2) as graduation_rate_Asian,
round(avg(C150_4_AIAN), 2) as graduation_rate_American_Indian
from school..completion_college_data$


/*Admin rates and SAT_AVG does these have a correlation?*/
select ADM_RATE,SAT_AVG, control, INSTNM
from school..school_college_data$ as school
join school..admissions_college_data$ as admin
on school.UNITID = admin.UNITID
where ADM_RATE is not null and SAT_AVG is not null
order by ADM_RATE DESC

/*Repayment rates for completers and non completers*/
select COMPL_RPY_1YR_RT, NONCOM_RPY_1YR_RT
from school..repayment_college_data$

/*total debt from all schools*/
select INSTNM, GRAD_DEBT_MDN, sum(GRAD_DEBT_MDN) over (order by INSTNM DESC) as running_total_debt
from school..aid_college_data$ as aid
join school..school_college_data$ as school
on aid.UNITID = school.UNITID
where GRAD_DEBT_MDN is not null
group by INSTNM, GRAD_DEBT_MDN

/*Running debt and % by state*/
with state_debt as
(
select STABBR, sum(GRAD_DEBT_MDN) as student_debt
from school..aid_college_data$ as aid
join school..school_college_data$ as school
on aid.UNITID = school.UNITID
where GRAD_DEBT_MDN is not null
group by STABBR
/*order by STABBR*/
) Select STABBR, student_debt, sum(student_debt) over (order by student_debt)/ sum(student_debt) over () as cum_percent
from state_debt
order by cum_percent


/* top 3 schools that take the longest to pay back (look for some after ten year mark $ or repayment percentage) use avg and group by school name)*/
