********************** FITTING CUBIC SPLINE  ************************************
*** DON'T THINK THERE IS ANY NEED TO DO THIS WITHIN MI
*** JUST AS GOOD TO APPEND ALL THE IMPUTED DATASETS AND THEN COLLAPSE INTO ONE AND 
*** DO EXACTLY WHAT BASIA DID PREVIOUSLY.

*Sep 2021 ES adapted this to include calendar year (fouryear) and to use Stata's cubic spline command stpm2 instead of Basia's first principles code

di in red upper("${sitename}")
frame change default
************************************
*** GET ALL MI DATASETS AND APPEND
************************************
clear
cd ${alphapath}/ALPHA\Incidence_ready_data/${sitename}/mi_data/
local filetomerge: dir "${alphapath}/ALPHA\Incidence_ready_data/${sitename}/mi_data/" files "incidence_ready_MI_${sitename}_*"
di `filetomerge'
append using `filetomerge',keep( idno sex dob study_name age years_one agegrp fouryear _* serocon_fail start_ep_date end_ep_date fifteen) generate(imps)
rename idno idnoold
egen idno=group(imps idno)
qui compress

************************************/

*use "${alphapath}/ALPHA\Incidence_ready_data/${sitename}/mi_data/incidence_ready_MI_${sitename}_20",clear

************************************
* SET UP FRAME FOR RESULTS
************************************

cap frame drop postnegages
frame create postnegages str50 str_study byte study_name sex fouryear age_last_test postnegage above95 no_haz_estimate above_max_age df


************************************
* BRING IN DATA AND FIT MODELS AND EXPORT RESULTS
************************************
summ study_name,
local study=`r(mean)'

foreach sex in 1 2 {
local sname:label (sex) `sex'
di in white "`sname'"
levels fouryear if sex==`sex',local(flist)
foreach f in `flist' {
local fname:label (fouryear) `f'
di in white "`fname'"
count if sex==`sex' & fouryear==`f' & _d==1
local enough=r(N)
if `enough'>5 {
*DIFFICULT TO KNOW WHAT DF TO USE- DIFFERENT SEX/YEAR COMBINATIONS SEEM TO REQUIRE DIFFERENT ONES
*START AT 5 AND WORK BACKWARDS
cap streg if sex==`sex' & fouryear==`f',d(e)
if _rc==0 {


foreach df in 10 9 8 7 6 5 4 3 2 1 {
local dfuse=`df'
cap stpm2 if sex==`sex' & fouryear==`f',df(`df') scale(hazard) eform iterate(100)
if _rc==0 {
qui: stpm2 if sex==`sex' & fouryear==`f',df(`df') scale(hazard) eform iterate(100)
*store df for this run
if `e(converged)'==1 { 
*have found maximum df at which model will converge so stop loop
continue,break
}
} /*close if which checks if the stpm2 can fit */
} /*close df loop */

*run model with max df
cap stpm2 if sex==`sex' & fouryear==`f',df(`dfuse') scale(hazard) eform 
if _rc==0 {
stpm2 if sex==`sex' & fouryear==`f',df(`dfuse') scale(hazard) eform 


preserve
qui: predict predhaz,haz

*reduce to one record per time
collapse (mean) predhaz (sum) _d if sex==`sex' & fouryear==`f',by(sex fouryear _t)
*keep only integers of _t 
qui: gen int_t=int(_t)
collapse (mean) predhaz (sum) _d if sex==`sex' & fouryear==`f',by(sex fouryear int_t)
*qui: keep if _t==int_t
qui: rename int_t _t
*sort _t

qui: gen prob_stay_neg=exp(-0.5*(predhaz+predhaz[_n+1])) //probability of not seroconverting by the end of the year

*need to loop through and generate the cum_neg variables, one variable for each age
forvalues i=14/100 {
*calculate the cumulative probability of remaining negative given a negative test at age `i'
qui: gen cum_neg`i'=.
qui: replace cum_neg`i'=1 if _t==`i'
qui: replace cum_neg`i'=prob_stay_neg*cum_neg`i'[_n-1] if _t>`i'

*models and hazard estimated for an age range that is typically a lot less than 100
sort _t
local above_max_age=0
summ _t
local tmax=r(max)
*this age is above the age range estimated in the model- put that in output data and go on to next age
if `i'>`tmax' {
local above_max_age=1
local postnegage=999
local above95=0
local no_haz_estimate=1
frame post postnegages ("${sitename}") (`study') (`sex') (`f') (`i') (`postnegage') (`above95') (`no_haz_estimate') (`above_max_age') (`dfuse')
*will then go to next age- want all the ages in the dataset
}

*if i (theoretical age last negative) is in the age range of the model
if `i'<=`tmax' {
	summ _t if cum_neg`i'<.
	local startval=r(min) 
	local endval=r(max)
	local nrecs=r(N)
	*if the hazard has been estimated then pick up the data and send to output dataset

	if `nrecs'>1 {

		*Loop down observations and find row numbers for the start and end of the timespan for the hazards experienced from this starting age
		count
		local recs=r(N)
		forvalues u=1/`recs' {
			if _t[`u']==`startval' {
				local startrec=`u' 
			}
			if _t[`u']==`endval' {
				local endrec=`u' 
			}
		}

		*now have 
		forvalues x=`startrec'/`endrec' {
			local y=cum_neg`i'[`x']
			local postnegage=_t[`x']
			local above95=0
			local no_haz_estimate=0

			if `y'<0.95 {
				continue,break
			} /*close break if */
			*if on last record and still going round loop
			if `x'==`endrec'  {
				* if  there is no estimate below 95%- flag this
				if `y'>=0.95 & `y'<.{
					local above95=1
				} /*close not below 95 if */
			}/*close last record if */

		} /*close if for going through records where a hazard has been estimated */
	} /*close records loop - some records with a hazard*/

	*In the age range for the model but there is no hazard estimate
	if `nrecs'==0 {
	local postnegage=888
	local above95=0
	local no_haz_estimate=1
	local above_max_age=1
	} /*close if for there being no records at this age with a hazard estimated */


	di `postnegage'
	frame post postnegages ("${sitename}") (`study') (`sex') (`f') (`i') (`postnegage') (`above95') (`no_haz_estimate') (`above_max_age') (`dfuse')
	macro drop postnegage above95 no_haz_estimate
	} /* close if for being in the age range of the model */

} /*close forvalues for ages */

restore
} /*close if for the actual model fitting ok */
} /*close if which checks if the streg fits OK- i.e. is there data for this combination */
} /*close the enough loop */
} /*close fouryear loop */
} /*close sex loop */
frame  postnegages {

drop if age_last_test==14
drop if age_last_test>89
gen age=age_last_test
do "${alphapath}/ALPHA\DoFiles\Common\create_agegrp_from_age.do" 

*make postneg years
gen timepostneg=postnegage- age_last_test

replace timepostneg=. if no_haz_estimate==1
replace timepostneg=. if above_max_age==1
replace timepostneg=. if above95==1
*If the cumulative prob never falls below 95% in the predicted values then give them the previous age's postneg + 5 years follow up
*happens when incidence is low and typically at the older ages where the follow up is truncated
sort sex fouryear age
egen last_val_timepostneg=lastnm(timepostneg),by(sex fouryear )
bys sex fouryear:egen tempmax=max(last_val_timepostneg)
replace last_val_timepostneg=tempmax if last_val_timepostneg==.

replace timepostneg=last_val_timepostneg+5 if above95==1 


bys sex fouryear agegrp:egen nohaz=total(no_haz_estimate)
bys sex fouryear agegrp:egen allabove_max_age=total(above_max_age)
*all the ones without hazards are for ages outside (above) the age range of the model
*so we are on shaky ground with knowing what the incidence is at those older ages. 
*safest thing to do

*if there are odd ones missing, rather than the whole age group, fill in using the means
bys sex fouryear agegrp:egen meantime=mean(timepostneg)
replace timepostneg=meantime if timepostneg==. & meantime<. & nohaz>0 & nohaz<.


*if there is no estimate for the whole age group give them the last age category's values + 5 years (to be consistent with above)
bys sex fouryear agegrp:egen agegrpmean=mean(timepostneg)

sort sex fouryear agegrp
egen last_meanval_timepostneg=lastnm(agegrpmean),by(sex fouryear )
*these egenmore commands are annoying and don't fill in the new var if the original is missing
bys sex fouryear: egen tmpmeanval=max(last_meanval_timepostneg)
replace last_meanval_timepostneg=tmpmeanval if last_meanval_timepostneg==.

replace timepostneg=last_meanval_timepostneg+5 if nohaz==5 



drop tmpmeanval last_meanval_timepostneg agegrpmean meantime allabove_max_age nohaz tempmax last_val_timepostneg
save ${alphapath}/ALPHA\Estimates_Incidence\Post_negative_times/post_neg_ages_${sitename},replace
}





