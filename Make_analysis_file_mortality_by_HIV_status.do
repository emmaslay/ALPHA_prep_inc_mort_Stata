*MAKE ALPHA MORTALITY BY HIV STATUS DATASET
*IN THE SPIRIT OF THE GATES MORTALITY ANALYSIS
*DON'T BRING IN CARE CONT VARS HERE BECAUSE NEED TO BRING IN MILLY AND CLARA'S NEW WAY OF DOING THOSE
*Starts from the residency and HIV tests specs, makes an analysis file for each site and then pools them.



************************************************************************************************************
************		       	3. MERGES, RETAIN RELEVANT RECORDS AND STSET	   	   	            ************
************************************************************************************************************

******************************************************************************************
**  		3.1. MERGE SPECS TOGETHER & TEMPORARY STSET TO MANIPULATE RECORDS           **
******************************************************************************************
*merge all specs to residency, keeping only those who also have residency information (appearing on 6.1)
use "${alphapath}/ALPHA/clean_data/${sitename}/residency_${sitename}",clear


	*For Manicaland, drop out the communities that weren't included in R6
	if lower("${sitename}")=="manicaland" {
	tempname community
	gen `community'=int(hhold_id/10000)
	tab `community'
	drop if `community'==1 |`community'==6 |`community'==11 |`community'==12
	}
	** For uMkhanyakude drop TasP people
	local lowsite=lower("${sitename}")
	if "`lowsite'"=="umkhanyakude" {
	drop if entry_type==1 & year(entry_date)==2017
	}

	** For Kisumu keep only Gem
	local lowsite=lower("${sitename}")
	if "`lowsite'"=="kisumu" {
		keep if residence==2
		}

*HIV testing
merge m:1 study_name idno using "${alphapath}/ALPHA\Prepared_data/${sitename}/hiv_tests_wide_${sitename}.dta", generate(merge_6_1_and_6_2)   ///
keepusing(first_neg_date last_neg_date first_pos_date last_pos_date  lasttest_date firsttest_date )
drop if merge_6_1_and_6_2==2
*metadata
merge m:1 study_name using "${alphapath}/ALPHA\Clean_data\alpha_metadata.dta",gen(merge_meta) keepusing(earlyexit_max)
drop if merge_meta==2


*labels
label define sex 1 "Men" 2 "Women",modify
label values sex sex


*STSET - death (exit type 2) is failure
cap n stset,clear
gen exit = exit_date
gen entry = entry_date
format %td entry exit
stset exit, time0(entry) failure(exit_type==2) origin(dob) id(idno) scale(365.25) 

******************************************************************************************
**  		3.2. DROP RECORDS BEFORE AGE OF 15            **
******************************************************************************************
*split at age 15 and drop all episodes before this age
stsplit pre15,at(15)
drop if pre15==0
drop pre15


******************************************************************************************
**  		3.3. CHECK CONSISTENCY OF START/END DATES ACROSS SPECS AND CORRECT          **
******************************************************************************************

**EARLY EXIT ISSUES
bys study_name idno (entry_date):gen episode_sequence=_n
bys study_name idno (entry_date):gen episode_total=_N
gen last_episode=0
replace last_episode=1 if episode_sequence==episode_total
gen temp=exit if last_episode==1
bys study_name idno: egen last_exit_original=max(temp)
drop temp

*if exit is on the same date as the last test, move the exit date to one day after
gen early_exit_fixed_t=1 if exit==lasttest_date & lasttest_date<. & last_episode==1
replace exit=exit+1 if exit==lasttest_date & lasttest_date<. & last_episode==1

*identify people whose latest 6.1 exit is before latest 6.2, 9.1 or 9.2 report & calculate difference
* exit before last test
gen exitgap_test=lasttest_date-exit if exit<lasttest_date & lasttest_date<. & last_episode==1
gen early_exit_problem=.
label define early_exit_problem 1 "Exit<last6.2" 2 "Exit<last9.1" 3 "Exit<last9.2" 4 "Exit<last6.2&9.1" 5 "Exit<last6.2&9.2" 6 "Exit<last 9.1&9.2" 7 "Exit<last6.2&9.1&9.2", modify
replace early_exit_problem=1 if exitgap_test~=. 

label values early_exit_problem early_exit_problem

*change exit to one day after last test, SR or clinic report [all exit types for first 2, only if not dead or out-migrated for clinic data as they could move out but still go to same clinic]
*May 2015, stop moving exit to after last clinic date as biased towards positive now we have more data
gen exit_new=.
label define early_exit_fixed 0 "No change to exit" 1 "Exit changed to last 6.2 plus 1 day" 2 "Exit changed to last 9.1 plus 1 day" 3 "Exit changed to last 9.2 plus 1 day"
replace early_exit_fixed_t=1 if exitgap_test<=earlyexit_max
replace exit_new=lasttest_date+1 if early_exit_fixed_t==1
replace early_exit_fixed=0 if early_exit_problem~=. & early_exit_fixed_t==.
bys study_name idno: egen early_exit_fixed=max(early_exit_fixed_t)
label values early_exit_fixed early_exit_fixed

replace exit=exit_new if exit_new~=.

******************************************************************************************
**  		3.4. stset FOR ANALYSIS                                                     **
******************************************************************************************

*redo stset to account for changes in exit dates & failure updates
cap n stset,clear
stset exit , time0(entry) failure(exit_type==2) origin(dob) id(idno) scale(365.25) 

*--end-3----------------------------------------------------------------------------------------------------*





***********************************************************************************************************
**  	 						     4. SPLIT AT Calendar years               				   			  **
************************************************************************************************************


do "${alphapath}/ALPHA\DoFiles\Common\Calendar_year_split.do" 
do "${alphapath}/ALPHA\DoFiles\Common\create_fouryear.do" 
drop if years_one<1989
qui compress

****************************************************************************
**	     5. SPLIT AT SINGLE YEARS AND MAKE 5 YEAR AGEGRP  	   			  **
****************************************************************************

do "${alphapath}/ALPHA\DoFiles\Common\single_year_agegrp_split_including_kids.do" 
do "${alphapath}/ALPHA\DoFiles\Common\create_agegrp_from_age.do" 

qui compress
*--end-5-------------------------------------------------------------------*







****************************************************************************
************     	6. ASSIGN HIV STATUS                        	   	 ***
****************************************************************************

*post negative times from cubic spline
*this is essentially a merge but will be done using frames (new in Stata 17) because it is more versatile
cap frame drop timesformerge
frame create timesformerge
frame timesformerge:use "${alphapath}/ALPHA\Estimates_Incidence\Post_negative_times/post_neg_ages_${sitename}"
frlink m:1 sex age fouryear ,frame(timesformerge) gen(link_bbe)
frget timepostneg,from(link_bbe)

*some aren't linked because that fouryear/age combination doesn't exist
*this is usually because there is no HIV data, to solve this carry forwards estimates from earlier period
** for sites which have stopped testing, copy forwards the old estimates
frame timesformerge:gen fouryear_forwards1=fouryear+1
frame timesformerge:gen fouryear_forwards2=fouryear+2
frlink m:1 sex age fouryear ,frame(timesformerge sex age fouryear_forwards1) gen(link_bbe_offset1)
frget timepostneg_offset=timepostneg,from(link_bbe_offset1)
replace timepostneg=timepostneg_offset if timepostneg==. & timepostneg_offset<.

drop timepostneg_offset link_bbe_offset1 link_bbe



**HIV STATUS based on 6.2b data
*need a value here for pre-positive time so the do file can run, but will later discard all the pre-positive time and make it unknown 
gen timeprepos=1
gen sero_conv_date=(last_neg_date+first_pos_date)/2
*am going to add 6 months to the time post-negative test to allow enough time for the next interview
replace timepostneg=timepostneg+0.5
do "${alphapath}/ALPHA/dofiles/common/create_hivstatus_detail.do"

*time before a first test and after the cutoff after a negative test is unknown, 
*in the seroconversion interval the years are allocated to negative up to the timepostneg cutoff then to unknown until the first positive test
label define hivstatus_broad 1 "Negative" 2 "Positive" 	3 "Unknown",modify
gen hivstatus_broad = hivstatus_detail
/*
1 "Negative" => 1
2 "Positive"  => 2

3 "Before first negative test" => 3
4 "Post Negative within cutoff" =>1
5 "Post negative beyond cutoff" => 3

6 "After last positive test" =>2
7 "Pre positive within cutoff" =>3
8 "pre positive beyond cutoff" =>3

9 "SC interval post neg within cutoff" =>1
10 "SC interval post neg beyond cutoff" =>3
11 "SC interval pre positive within cutoff" =>3 
12 "SC interval pre positive beyond cutoff" =>3

13 "Unknown, never tested" => 3
*/
recode hivstatus_broad 1=1 2=2 3=3 4=1 5=3 6=2 7=3 8=3 9=1 10=3 11=3 12=3 13=3 
label values hivstatus_broad hivstatus_broad
tab hivstatus_detail hivstatus_broad,m
*--end-6---------------------------------------------------------------------------------------------------*



*************************************************************************************
************	16. SAVE SITE SPECFIC RESULTS READY FILES                   *********
*************************************************************************************
cd "${alphapath}/ALPHA\Ready_data_mortality"
cap mkdir "${sitename}"
cd "${sitename}"
*** ALL DATA***
qui compress
save "mortality_by_status_ready_${sitename}",replace


*--end-16---------------------------------------------------------------------------*



