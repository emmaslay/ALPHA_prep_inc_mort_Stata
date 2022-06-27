


*** define global macros used in documentation
local id ="s11"
local name="${alphadrive}/dofiles/common/five_year_agegrp_split_including_kids.do"
local level="common"
local calls=""
local uses="" 
local saves=""
local does="Splits person time, in an already stset dataset, into age in FIVE YEAR GROUPS- creates agegrp variable. Don't use this if already split on age, use create_agegrp_from_age.do"



************* SPLIT DATA INTO FIVE YEAR AGE GROUPS AND CREATE AGEGRP

stsplit agegrp, at(0(5)90)


recode agegrp 0=0 5=1 10=2 15=3 20=4 25=5 30=6 35=7 40=8 45=9 50=10 55=11 60=12 65=13 70=14 75=15 80=16 85=17 90=18
label define agegrp 0 "0-4" 1 "5-9" 2 "10-14" 3 "15-19" 4 "20-24" 5 "25-29" 6 "30-34" 7 "35-39" 8 "40-44" 9 "45-49" ///
 10 "50-54" 11 "55-59" 12 "60-64" 13 "65-69" 14 "70-74" 15"75-79" 16 "80-84" 17 "85-89" 18 "90+",modify
label values agegrp agegrp
label var agegrp "Five year age group"





*===================================================================================
* ADD INFO FOR DOCUMENTATION
*===================================================================================
*new way
char _dta[name_`id'] "`name'"
char _dta[calls_`id'] "`calls'"
char _dta[uses_`id'] "`uses'"
char _dta[saves_`id'] "`saves'"
char _dta[does_`id'] "`does'"

*this needs to be a list of all ids used in making the final dataset so append to this char
*no append option
local currentid:char _dta[id]
local newid="`currentid'" + " " + "`id'"
char _dta[id] "`newid'"

** attach a note describing provenance to each NEW variable- spec variables already have a [source]
qui desc ,varlist sh
local newvarlist=subinstr("`r(varlist)'","`oldvarlist'","",.)

foreach v in `newvarlist' {
local source:char `v'[source]
*if this is empty then
if "`source'"=="" {
char `v'[source] "`name'"
char `v'[id] "`id'"
} /*close if */

} /*close var loop */
