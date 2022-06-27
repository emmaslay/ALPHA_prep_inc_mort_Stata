*PREPARE AN HIV INCIDENCE ANALYSIS FILE FOR SHARING VIA THE DATAFIRST REPOSITORY
*START WITH THE INCIDENCE READY FILE- MIDPOINT
*MOVES ALL THE BIRTHDATES TO THE 15TH OF THE MONTH

frame change default
cd "${alphapath}/ALPHA\Data_sharing "

* get the rates used in original incidence analysis, only need to do this once
use "${alphapath}/ALPHA\Incidence_ready_data/${sitename}\incidence_ready_midpoint_${sitename}.dta",clear
**get current rate estimates for later comparison with those estimated from repository dataset

** ONLY KEEPING 15-49 YEAR OLDS
keep if age>14 & age<50
drop if fouryear>4
strate sex fouryear agegrp,output(results_comparison/incidence/original_rates_${sitename},replace)


********** MAKE DATASET FOR SHARING *************
use "${alphapath}/ALPHA\Incidence_ready_data/${sitename}/incidence_ready_midpoint_${sitename}.dta",clear

*get list of birthdates
preserve
keep sex idno dob
gen dummy=1
collapse (sum) dummy,by(idno sex dob)
save "dobs/incidence_real_dob_${sitename}",replace
restore

** ONLY KEEPING 15-49 YEAR OLDS
keep if agegrp>2 & agegrp<10
drop if fouryear>4
*and records that are stset
drop if _st==0

*round dob to 15th of the month
gen mob=month(dob)
gen yob=year(dob)
gen dayob=day(dob)
gen round_dob=mdy(mob,15,yob)

gen dob_offset=dob-round_dob

*make new entry and exit variables which line up with the new dob
gen double round_start_ep_date =start_ep_date+dob_offset
gen double round_end_ep_date=end_ep_date+dob_offset
gen double round_fifteen=fifteen+dob_offset
gen double round_lastneg=last_neg_date+dob_offset
gen double round_firstpos=first_pos_date+dob_offset

stset,clear
stset round_end_ep_date, id(idno) failure(serocon_fail) time0(round_start_ep_date) enter(time round_fifteen) origin(time round_dob) scale(365.25)

*now need to reset on age not dates
*make new variables containing the stset information - dataset already split so can then discard dob and residency and test dates
gen double timein=_t0
gen double timeout=_t
gen fail=_d

gen double timelastneg=(round_lastneg-round_dob)/365.25
gen double timefirstpos=(round_firstpos-round_dob)/365.25
*** doing this makes some people aged 14 and then they don't enter into analysis because they are too young.
*will allow them to drop out for now- otherwise, if we round them up it will have to be a whole month, rather than just enough to enter at 15

***********************************************************
** NEW STSET ON AGE USING LESS PRECISE ANALYSIS TIME
***********************************************************

stset,clear

keep study_name idno timein timeout timelastneg timefirstpos fail fouryear  birth_cohort agegrp  sex 

stset timeout,entry(time 15) time0(timein) failure(fail) id(idno) 


*** Need to redo stsplit on age to fix the people who have been bumped into the wrong category by rounding
rename agegrp old_agegrp
do  "${alphapath}/ALPHA\DoFiles\Common\Five_year_agegrp_split_including_kids.do" 
drop old_agegrp
keep if agegrp>2 & agegrp<10

**********************************************************************************
*now need to collapse to put together the same age group- won't affect stata but the existence of a split is informative
*first need to account for gaps in residency so we don't collapse them and discard the gap
**********************************************************************************
save temp,replace

**** work out who has gaps and where
sort study_name idno _t0
bys study_name idno (_t0):gen rec_seq=_n
gen gap_before=0
bys study_name idno (_t0):replace gap_before=rec_seq if _t0~=_t[_n-1] & rec_seq>1
**now identify contiguous episodes
gen collapsegrp=gap_before
bys study_name idno agegrp fouryear (_t0):replace collapsegrp=collapsegrp[_n-1] if gap_before==0 & _n>1


drop if _st==0
collapse (min) timein _t0 (max) timeout _t fail _st _d ,by(study_name idno sex  agegrp fouryear collapsegrp timelastneg timefirstpos)

label var idno "Participant ID number"
label var study_name "Study name"
label var sex "Sex"
label var timein "Start of episode (age)"
label var timeout "End of episode (age)"
label var timelastneg "Age at last negative test"
label var timefirstpos "Age at first positive test"
label var fail "Seroconversion occurred at the end of this episode"
label var _st "Stata variable: in survival analysis"
label var _d "Stata variable: failure (seroconversion)"
label var _t0 "Stata variable: age at start of episode"
label var _t "Stata variable: age at end of episode"
label define yesno 0 "No" 1 "Yes",modify
label values fail yesno
rename idno idno_internal
egen idno=group(idno_internal)
label var idno "Participant ID number for sharing"
order study_name idno* sex fouryear agegrp timein timeout timelastneg timefirstpos fail _*

save "${alphapath}/ALPHA\Data_sharing/Incidence_data_for_sharing/incidence_${sitename}",replace

*get incidence rates for comparison
strate sex fouryear agegrp,output(results_comparison/incidence/sharing_rates_${sitename},replace)






*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=


************************************************************
* PUT ALL THIS INTO TABLES
************************************************************


************************************************************
** SET UP DOCUMENT TO REPORT PROGRESS
************************************************************
cap putdocx clear
putdocx begin
putdocx paragraph,style(Heading1)
putdocx text ("Comparison of incidence datasets used for analysis and sharing"), linebreak
putdocx text ("${sitename}") 
** add in tables 1 & 2 with captions and notes
putdocx paragraph,style("Heading2")
putdocx text ("Number of people with different sex/dob combinations")

putdocx table table1=(5,3)
putdocx table table1(1,2)=("Original dataset")
putdocx table table1(1,3)=("Simplified dataset")
putdocx table table1(2,1)=("Number of people contributing to incidence analysis:")
putdocx table table1(3,1)=("Number of different sex/dob combinations in dataset:")
putdocx table table1(4,1)=("Number of back-calculated dob that match actual (+/- 2 days):")
putdocx table table1(5,1)=("Number of unique back-calculated dob/sex combinations that match actual:")


#delimit;

putdocx paragraph;
putdocx text ("Table 1: Numbers of individuals in original and simplified datasets, by information on date of birth");

putdocx paragraph;
putdocx text ("In the simplified dataset we do not provide date of birth but for some people it can be derived from the age given
at the start of a calendar year period.  This shows how many people have unique combinations of sex and date of birth
in the original data and the simplified version and, for the simplified version, how many of those unique combinations can be 
recovered by back-calculating date of birth. To end up with fewer unique combinations we could round birthdates to the nearest 
quarter, or 6-months. This would have more impact on the rate estimates, and even quarterly birthdates doesn't remove all the
unique combinations"); 

#delimit cr

putdocx table table2=(14,3)
putdocx table table2(1,1)=("Number of people of the same sex who share a birthday:")
putdocx table table2(1,2)=("Number of people")
putdocx table table2(2,2)=("Original dataset")
putdocx table table2(2,3)=("Simplified dataset")
putdocx table table2(3,1)=("1 person (unique combination)")
putdocx table table2(4,1)=("2 people")
putdocx table table2(5,1)=("3 people")
putdocx table table2(6,1)=("4 people")
putdocx table table2(7,1)=("5 people")
putdocx table table2(8,1)=("6 people")
putdocx table table2(9,1)=("7 people")
putdocx table table2(10,1)=("8 people")
putdocx table table2(11,1)=("9 people")
putdocx table table2(12,1)=("10+ people")
putdocx table table2(13,1)=("Can't estimate dob")
putdocx table table2(14,1)=("Total")

#delimit;

putdocx paragraph;
putdocx text ("Table 2: Numbers of people with various sex/date of birth combinations in the original and simplified datasets");
putdocx paragraph;
putdocx text ("In the simplified dataset there may be more unique birthdate/sex combinations than there were in the original data. 
This is because we can't back-calculate the date of birth for everyone in the dataset, and some of those without a
back-calculated date of birth previously shared a birthdate with one or more individuals of the same sex. Although 
it seems that this would worsen the anonymisation it does not. When merged with another data source it would not be
 possible to link the records with any certainty as there would be multiple possible matches.");
#delimit cr

*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*use original data
*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

use "${alphapath}/ALPHA\Incidence_ready_data/${sitename}/incidence_ready_midpoint_${sitename}.dta",clear

*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*get stset info for comparison table 3
stdes
local st_people_orig=`r(N_sub)'
local st_records_orig=`r(N_total)'
local st_fail_orig=`r(N_fail)'
local st_gap_time_orig=`r(gap)'
local st_gap_people_orig=`r(N_gap)'
local st_ptime_orig:di %12.1f `r(tr)'

*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
**** see how many unique sex and dob combinations there are- for table 2
gen dummy=1
collapse (count) dummy,by(study_name idno sex dob)
unique sex dob
local unique_orig=r(unique)
local people_orig=r(N)
replace dummy=1
collapse (sum) dummy,by(study_name sex dob)
gen d=dummy
recode dummy 10/max=10
collapse (sum) d,by(study_name sex dummy)

putdocx table table1(2,2)=("`people_orig'")
putdocx table table1(3,2)=("`unique_orig'")



*** FILL IN ORIGINAL NUMBERS FOR TABLE 2

forvalues n =1(1)10 {
local rownum=`n'+2
*add in a blank row before the total
cap total d if dummy==`n'
if _rc==0 {
qui total d if dummy==`n'
local freq=r(table)[1,1]
putdocx table table2(`rownum',2)=("`freq'")
}
}
total d
local freq=r(table)[1,1]

local rownum=`rownum'+2
putdocx table table2(`rownum',2)=("`freq'")
macro drop   freq


*********************************
* USE SHARING DATASET
*********************************

use "${alphapath}/ALPHA\Data_sharing/Incidence_data_for_sharing/incidence_${sitename}",clear


** summarise stset info for sharing data
stdes
local st_people_simple=`r(N_sub)'
local st_records_simple=`r(N_total)'
local st_fail_simple=`r(N_fail)'
local st_gap_time_simple=`r(gap)'
local st_gap_people_simple=`r(N_gap)'
local st_ptime_simple: di %12.1f `r(tr)'

** add table 3 to doc and populate
putdocx paragraph,style("Heading2")
putdocx text ("stset comparison")

putdocx paragraph
putdocx table table3=(7,3)
putdocx table table3(1,1)=("")
putdocx table table3(1,2)=("Original")
putdocx table table3(1,3)=("Simplified")

putdocx table table3(2,1)=("Number of people")
putdocx table table3(3,1)=("Person time")
putdocx table table3(4,1)=("Number of seroconversions")
putdocx table table3(5,1)=("Number of records")
putdocx table table3(6,1)=("Number of people with a gap")
putdocx table table3(7,1)=("Mean length of gap")

putdocx table table3(2,2)=("`st_people_orig'")
putdocx table table3(3,2)=("`st_ptime_orig'")
putdocx table table3(4,2)=("`st_fail_orig'")
putdocx table table3(5,2)=("`st_records_orig'")
putdocx table table3(6,2)=("`st_gap_people_orig'")
putdocx table table3(7,2)=("`st_gap_time_orig'")

putdocx table table3(2,3)=("`st_people_simple'")
putdocx table table3(3,3)=("`st_ptime_simple'")
putdocx table table3(4,3)=("`st_fail_simple'")
putdocx table table3(5,3)=("`st_records_simple'")
putdocx table table3(6,3)=("`st_gap_people_simple'")
putdocx table table3(7,3)=("`st_gap_time_simple'")

macro drop st_people_orig st_ptime_orig st_fail_orig st_records_orig st_gap_people_orig st_gap_time_orig
macro drop st_people_simple  st_ptime_simple st_fail_simple st_records_simple st_gap_people_simple st_gap_time_simple

#delimit ;
putdocx paragraph;
putdocx text
("This is the information from Stata's stset command and is the data that will be used for survival analysis.
We lose a few failure events (seroconversions) after rounding the dates of birth because some events fall out of the age range.
We also lose some residency gaps I think for the same reason.");
#delimit cr

*===================================================




************************************************************************
*** look at number of people with same sex & dob in simplified dataset
************************************************************************
frame change default
cap frame drop simp



use "${alphapath}/ALPHA\Data_sharing/Incidence_data_for_sharing/incidence_${sitename}",clear

stdes
gen dummy=1
drop if _st==0
*need to get a back-calculated date of birth
gen startyear=1995 if fouryear==0
replace startyear=2000 if fouryear==1
replace startyear=2005 if fouryear==2
replace startyear=2009 if fouryear==3
replace startyear=2013 if fouryear==4


gen endyear=2000 if fouryear==0
replace endyear=2005 if fouryear==1
replace endyear=2009 if fouryear==2
replace endyear=2013 if fouryear==3
replace endyear=2017 if fouryear==4

gen interval_length=endyear-startyear

*** complete follow up time in this interval?
*get rid of the age-splits
sort idno _t0  fouryear agegrp collapsegrp _t0
bys idno fouryear agegrp collapsegrp (_t0):gen to_combine=_n

*** only if contiguous

collapse (min) timein _t0 (max) timeout _t,by(idno sex fouryear startyear endyear interval_length to_combine)
gen fup=timeout-timein
gen complete=0
replace complete=1 if fup==interval_length
unique idno if complete==1
local comp_dob=`r(unique)'

**** work out an estimated date of birth
gen double dob=int(mdy(1,1,startyear)-_t0*365.25)
format dob %td
sort idno

*For people with at least one complete interval this is a decent estimate of their dob
*BUT due to rounding errors, for people with >1 complete interval there may be 1 day differences in the derived dob 
*fix this-
bys idno :egen fixed_dob=mean(dob) if complete==1
format fixed_dob %td
replace dob=fixed_dob if complete==1 
drop fixed_dob


**FLAG PEOPLE WHO HAVE A COMPLETE INTERVAL
bys idno:egen ever_complete=max(complete)

**OPTIONS
*1 COMPLETE INTERVAL- STRAIGHTFORWARD TO CALCULATE DOB, MAY STILL HAVE SOME WRONG ONES FROM INCOMPLETE INTERVALS- THEY NEED TO BE DROPPED
drop if ever_complete==1 & complete==0
*send these off to other frame and then drop
count if ever_complete==1
if r(N)>0 {
preserve
keep if ever_complete==1
collapse (sum) ever_complete if complete==1,by(sex idno dob)
cap frame drop simp
frame copy default simp
restore
}
drop if ever_complete==1

*2 NOT ENOUGH INCOMPLETE INTERVALS TO FIND A PATTERN- ONLY ONE ESTIMATED DOB 
bys idno:gen N=_N
preserve
keep if N==1
collapse (sum) N ,by(sex dob idno)
gen ever_complete=2
replace dob=.
cap frame create simp
frame simp:frameappend  default 
restore
drop if N==1

*3 ENOUGH INCOMPLETE INTERVALS TO FIND A PATTERN - A MOST COMMON ESTIMATED DOB- or not - EQUAL NUMBERS OF ESTIMATES FOR DIFFERENT DATES

*the end of the interval might also be informative here so see what dob that yields
gen double dob2=int((mdy(1,1,endyear) -1)-_t*365.25)
format dob2 %td
keep idno sex fouryear dob dob2
rename dob dob1
reshape long dob,i(idno sex fouryear)
*see if the same dob has been estimated on different records


sort idno dob
bys idno:gen dob_diff=dob-dob[_n-1]
recode dob_diff .=0 2/max=0
bys idno:replace dob_diff=1 if dob_diff==0 & dob_diff[_n+1]==1
*fix 1 day differences caused by rounding errors-
bys idno :egen fixed_dob=mean(dob) if dob_diff==1
format fixed_dob %td
replace dob=fixed_dob if dob_diff==1 
drop fixed_dob dob_diff


gen dummy=1
collapse (sum) dummy,by(idno sex dob)

bys idno:egen max_n_rec=max(dummy)
gen ever_complete=3 if dummy==max_n_rec

*keep the most common one
keep if dummy==max_n_rec


*people for whom each record is different
replace dob=. if dummy==1
replace ever_complete=4 if dummy==1

*some people who have two dates which both occur the same number of times- drop
bys idno:gen N=_N if dob<.
replace dob=. if N>1
replace ever_complete=4 if N>1

collapse (sum) dummy,by(idno sex dob ever_complete)
drop dummy
*add these to the frame 
frame simp:frameappend  default 


**** SUMMARISE HOW MANY PEOPLE IN SIMPLIFIED DATASET HAVE UNIQUE SEX/DOB COMBINATIONS (EVEN THOUGH THE DOBS ARE BASED ON ROUNDED DATA)
di "SUMMARISE HOW MANY PEOPLE IN SIMPLIFIED DATASET HAVE UNIQUE SEX/DOB COMBINATIONS (EVEN THOUGH THE DOBS ARE BASED ON ROUNDED DATA)"
frame change simp
drop N
label define ever_complete 1 "Can estimate- complete interval" 2 "Can't estimate- only 1 incomplete" 3 "Can estimate, multiple incomplete" 4 "Can't estimate, multiple incomplete",modify
label values ever_com ever_complete 
drop if ever_complete==.

rename dob est_dob

merge 1:1 sex idno using "dobs/incidence_real_dob_${sitename}"
drop if _m==2
drop dummy
format dob est_dob %td

save "dobs/incidence_real_and_est_dob_${sitename}",replace

*COLLAPSE IT AGAIN TO SUM COMBINATIONS
gen dummy=1
collapse (sum) dummy ,by(sex est_dob)
gen d=dummy

recode dummy  10/max=10
replace dummy=11 if est_dob==. 
collapse (sum) d,by( sex dummy)


forvalues n =1(1)11 {
local rownum=`n'+2
cap total d if dummy==`n'
if _rc==0 {
total d if dummy==`n'
local freq=r(table)[1,1]
putdocx table table2(`rownum',3)=("`freq'")
}
}

total d 
local freq=r(table)[1,1]
local rownum=`rownum'+1
putdocx table table2(`rownum',3)=("`freq'")
macro drop  freq


***************************************************************
** FILL IN TABLE 1 
***************************************************************
di "FILL IN TABLE 1 "
frame change default

use "dobs/incidence_real_and_est_dob_${sitename}",clear

*** difference between estimated and actual
gen diff=abs(est_dob-dob)
count if diff<2
local samedob=r(N)

unique sex dob if diff<2
local unique_match=r(unique)
putdocx table table1(4,3)=("`samedob'")
putdocx table table1(5,3)=("`unique_match'")

unique idno
local people_simp = r(unique)


collapse (count) idno,by(sex est_dob)
count
local unique_simp=r(N)

putdocx table table1(2,3)=("`people_simp'")
putdocx table table1(3,3)=("`unique_simp'")

macro drop samedob unique_match people_orig unique_orig people_simp unique_simp



***************************************************************
** COMPARE RATES
***************************************************************
putdocx pagebreak
putdocx paragraph,style("Heading2")
putdocx text ("Comparison of rates from both datasets")
putdocx paragraph

clear
use results_comparison/incidence/original_rates_${sitename}
rename _* orig_*
label var orig_R "Rates from dataset used for papers"

merge 1:1 fouryear sex agegrp using results_comparison/incidence/sharing_rates_${sitename}
rename _* share_*
label var share_R "Rates from dataset used in incidence analyses"

format %5.3f orig_R  share_R

pwcorr share_R orig_R
local rho: di %4.3f `r(rho)'
graph twoway scatter share_R orig_R, || function y=x,range(0 0.017) name(rates,replace) scheme(mrc) legend(off) ///
ytitle("Rates from dataset for sharing after simplification") xtitle("Rates from dataset used for papers") ///
text(0.006 0.015  "correlation coefficient=`rho'") title("${sitename}")
graph export results_comparison/incidence/scatter_rates_${sitename}.png,replace
putdocx paragraph,style("Heading2")
putdocx text ("Overall correlation")
putdocx paragraph
putdocx image results_comparison/incidence/scatter_rates_${sitename}.png

reshape long @_D @_Y @_Rate @_Lower @_Upper,i(agegrp fouryear sex) j(version) string

gen rate=_Rate*100
gen ll=_L*100
gen ul=_U*100

replace agegrp=agegrp+0.2 if version=="share"

putdocx pagebreak
putdocx paragraph,style("Heading2")
putdocx text ("Differences between rates by sex, age and fouryear")

#delimit ;
putdocx paragraph;
putdocx text 
("Comparison of the sex- and age-specific rates estimated in each 
calendar year period, using the original and the simplified dataset for sharing.  
The rates are inevitably slightly changed by the changes to the birth dates which 
mean person time and events are shifted into different calendar year periods or
excluded from analyis. With rounding of birthdates to the 15th of the month differences are minimal");
#delimit cr

levels fouryear,local(flist)
foreach f in `flist' {
local flab:label (fouryear) `f'

graph twoway rspike ll ul agegrp if fouryear==3 & version=="orig", lcolor(navy) ///
 by(sex,legend(rows(1)) note("") caption("")) ///
|| rspike ll ul agegrp if fouryear==3 & version=="share", by(sex) lcolor(orange) ///
|| scatter rate agegrp if  fouryear==3 & version=="orig", by(sex)  mcolor(navy) ///
|| scatter rate agegrp if  fouryear==3 & version=="share", by(sex) mcolor(orange) ///
legend(rows(1) order(3 "Original version" 4 "Simplified version")) ///
xlab(3(1)9,val) ytitle("Incidence rate") title("${sitename} `flab'") 
graph export results_comparison/incidence/scatter_rates_${sitename}_`flab'.png,replace
putdocx paragraph
putdocx image results_comparison/incidence/scatter_rates_${sitename}_`flab'.png, width(14cm)
}

window manage close graph  _all
putdocx save results_comparison/incidence/incidence_comparison_summary_${sitename},replace











