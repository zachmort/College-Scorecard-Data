Questions to look into:
-what colleges have the most fin aid and have the most earings after graduation
-use field PCIP11 to see what the highest average salary is for college grads whose school has has higher than average for these program
-Use this field for addmissions rate analysis ADM_RATE
-Use this field for average SAT score for students admitted SAT_AVG
-Median debt for students that have completed school Field GRAD_DEBT_MDN (look at highs and lows)(same with these PCTPELL,PCTFLOAN)
Total outstanding federal Direct Loan balance LPSTAFFORD_AMT
Total outstanding Parent PLUS Loan balance LPPPLUS_AMT
Do colleges that have the most loans out have students graduate on time or do they normally take more time
-Use this: C150_4 for looking at completion rates of first time full year 4 year instits
Completion rates for all races :
C150_4_WHITE
C150_4_BLACK
C150_4_HISP
C150_4_ASIAN
C150_4_AIAN
C150_4_NHPI
C150_4_2MOR
C150_4_NRA
C150_4_UNKN
C150_4_WHITENH
C150_4_BLACKNH
C150_4_API
C150_4_AIANOLD
C150_4_HISPOLD

-First gen vs non first gen still enrolled rates at origional school after 2 years:
FIRSTGEN_ENRL_ORIG_YR2_RT
NOT1STGEN_ENRL_ORIG_YR2_RT

male vs female 4 year completion:
FEMALE_YR4_N
MALE_YR4_N

TRANS_4_POOLED
TRANS_L4_POOLED
Transfer rate for first-time, full-time students at four-year institutions (within 150% of expected time to completion/6 years)
Transfer rate for first-time, full-time students at less-than-four-year institutions (150% of expected time to completion)

NPT4_PUB
NPT4_PRIV
pulic vs private Net price for title IV

TUITIONFEE_IN
TUITIONFEE_OUT
instate tuition and fees vs out of state tuition and fees

BOOKSUPPLY
ROOMBOARD_ON
OTHEREXPENSE_ON
cost of attendence for books, room and other

MN_EARN_WNE_P10
MN_EARN_WNE_INDEP0_P10
MN_EARN_WNE_INDEP1_P10
mean earnings and not enrolled 10 years after entry
seperated by dependent vs independent students

MD_EARN_WNE_P10
med earings after 10 years an no enrty


COMPL_RPY_1YR_RT
NONCOM_RPY_1YR_RT
1 year repayment rate for completers and non completers


INSTNM-institution name
CITY
STABBR
ZIP
CONTROL - control of institution private public state
LOCALE - locale of in big city , small town ect

CCUGPROF
CCSIZSET
HBCU
PBI
ANNHI
TRIBAL
AANAPII
HSI
NANTI
MENONLY
WOMENONLY
-race and gender based schools


Net tuition revenue per full-time equivalent student	school	tuition_revenue_per_fte	integer		TUITFTE
Instructional expenditures per full-time equivalent student	school	instructional_expenditure_per_fte	integer		INEXPFTE
amount the college makes per student is it private/public? what do the students make in those schools that have higher tuition revenues

UGDS_WHITE
UGDS_BLACK
UGDS_HISP
UGDS_ASIAN
UGDS_AIAN
UGDS_NHPI
diversity of college students in schools

RET_FT4
full time first time retion rate at 4 year schools

Percent of students whose parents' highest educational level is middle school	student	share_firstgeneration_parents.middleschool	float		PAR_ED_PCT_MS
Percent of students whose parents' highest educational level is high school	student	share_firstgeneration_parents.highschool	float		PAR_ED_PCT_HS
Percent of students whose parents' highest educational level was is some form of postsecondary education	student	share_firstgeneration_parents.somecollege	float		PAR_ED_PCT_PS
parent education and then compare that with kid graduation in certain schools and states

Average family income in real 2015 dollars	student	demographics.avg_family_income	integer		FAMINC'





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
/*All data looks good expect*/

/*---------------------------------------Starting off with some basic questions---------------------------------------*/
/*What school is the largest
Enrollment of undergraduate certificate/degree-seeking students UGDS*/
select INSTNM, UGDS
from school..student_college_data$ as stud
join school..school_college_data$ as school
on school.UNITID = stud.UNITID
order by UGDS DESC

/*Look into if the schools with 0 students are schools that are shut down (there is a field that indicates if they are closed or not)*/
select INSTNM, UGDS
from school..student_college_data$ as stud
join school..school_college_data$ as school
on school.UNITID = stud.UNITID
order by UGDS ASC

/*most expensive schools*/

/*looks like field COSTT4_P is a navchar(22) type need to convert this*/
update school..cost_college_data$ set COSTT4_P = 0 where COSTT4_P is null
/*Now convert to an float*/
alter table school..cost_college_data$ alter column COSTT4_P int;
/*Replacing 0 values with NULL*/
update school..cost_college_data$ set COSTT4_P = NULL where COSTT4_P = 0

/*adding a combined column for COSTT4_P and COSTT4_A, Both of these are cost avergae costs for all aspects of schooling for acadmeic year and program schools*/
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
broken out public, private and non for profit*/
select STABBR, CONTROL, max(COSTT4_combined) over (partition by STABBR order by INSTNM), row_number(COSTT4_combined) over (partition by STABBR order by INSTNM)
from school..cost_college_data$ as cost
join school..school_college_data$ as sch
on sch.UNITID = cost.UNITID
/*where COSTT4_A is not null and COSTT4_P is not null*/
group by STABBR, CONTROL
order by STABBR, CONTROL

/*most expensive schools
do the most expensive schools take the longest to pay off???*/

/*earnings after graduation*/
select INSTNM
from
where

/*number of programs offered vs avg and plot % increase for each school
Diversity of schools academics*/

select INSTNM, max(PRGMOFR), avg(PRGMOFR) , max(PRGMOFR)/avg(PRGMOFR)
from
where

/*avg TUITIONFEE_IN, TUITIONFEE_OUT for all states*/

/*running total of NET TUTITION REVENUE PER STUDENT(includes graduate students) from all schools AND use a row that is the percentage of each amount relative to the total*/
select INSTNM,TUITFTE, avg(TUITFTE) over (order by TUITFTE DESC) as running_revenue_total_all_schools
from school..cost_college_data$ as cost
join school..school_college_data$ as school
on cost.UNITID = school.UNITID
where TUITFTE is not null

/*total debt out standing per race class in each state*/
