

local id ="p2"
local name="${alphapath}/ALPHA/dofiles/prepare_data/prepare_residency_summary_dates"
local level="prepare"

local calls=""
local uses="${alphapath}/ALPHA/clean_data/${sitename}/residency_${sitename}" 
local saves="${alphapath}/ALPHA/prepared_data/${sitename}/residency_summary_dates_${sitename}"
local does="Summarises the residency episodes in a wide file"


use "${alphapath}/ALPHA/clean_data/${sitename}/residency_${sitename}",clear
keep idno study_name entry_date exit_date residence

** For Kisumu keep only Gem
local lowsite=lower("${sitename}")
if "`lowsite'"=="kisumu" {
keep if residence==2
}

drop residence

bysort idno (entry_date):gen order=_n
	reshape wide entry_date exit_date,i(idno) j(order)
order study_name idno
/*
bys study_name idno (exit_date):gen last_res_episode=1 if _n==_N 
bys study_name idno (exit_date):gen first_res_episode=1 if _n==1 
gen last_exit_date=exit_date if last_res_episode==1
gen last_exit_type=exit_type if last_res_episode==1

gen first_entry_date=entry_date if first_res_episode==1
gen first_entry_type=entry_type if first_res_episode==1

collapse (min) last_exit* first_entry* ,by(study_name idno)
*/
*===============================================================================================
* ADD DOCUMENTATION INFORMATION
*===============================================================================================


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
char _dta[thisid] "`id'"
** attach a note describing provenance to each NEW variable- spec variables already have a [source]
qui desc ,varlist sh
foreach v in `r(varlist)' {
local source:char `v'[source]
*if this is empty then
if "`source'"=="" {
char `v'[source] "`saves'"
char `v'[id] "`id'"
} /*close if */

} /*close var loop */

*save the dataset
save ${alphapath}/ALPHA/prepared_data/${sitename}/residency_summary_dates_${sitename},replace

*document the data
local oldcd=c(pwd)
cd ${alphapath}/ALPHA/prepared_data_documentation/
cap mkdir ${sitename}
cd ${sitename}
do ${alphapath}/ALPHA/dofiles/document/Make_dataset_dictionary_with_char.do
cd "`oldcd'"

