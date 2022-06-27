
******* USES OPEN DATASET AND CREATES A DATA DICTIONARY IN THE WORKING DIRECTORY
*THIS IS A WORD DOC AND THE FILENAME IS THE DATASET NAME PREFACED WITH data_dictionary.
** THIS IS FOR BOTTOM LEVEL FILES ONLY- datasets prepared using "prepare_data" do files

*+=+=+=FOR COMPLETENESS, IT ISN'T USED =+=+=+
* define global macros used in documentation
local id ="d1"
*+=+=+=+=+=+=+=+=+=+=+=+=

*get date dataset was last saved in a nice format
global filedate= "_"  +word(c(filedate),1) + "_" + word(c(filedate),2) + "_"  + word(c(filedate),3) 
di "${filedate}"


*quietly {
*Extract information about the dataset and current date
global datafilename=c(filename)
global datafiledate=c(filedate)
global datalabel: data label 
global today=c(current_date)

*make short filename to include in output doc filename
local filename=subinstr("${datafilename}","/"," ",.)
local filename=subinstr("`filename'",".dta"," ",.)
local filewords:word count `filename'
local filename=word("`filename'",`filewords')

** extract information from char- added when file was created
local id: char _dta[thisid]

local notesinput: char _dta[uses_`id']
local notesdofile: char _dta[name_`id']
local notesdesc: char _dta[does_`id']
local notesoutput: char _dta[saves_`id']


*and information from notes
local nnotes:char _dta[notes0]
if "`nnotes'"~="" {
forvalues x= `nnotes'/1 {
local notesother: char _dta[note`x'] + "`notesother'"
} /*close forvalues */
} /*close if */

***** SET UP DOCUMENT AND WRITE HEADINGS
cap putdocx clear
putdocx begin, pagesize(A4)

putdocx paragraph,style(Title)
putdocx text ("Description of ${datafilename}") , font(Calibri, 16,) bold
putdocx paragraph
 putdocx text ("Dataset label: ${datalabel} ")
putdocx paragraph
 putdocx text ("This dictionary created on ${today} using dataset dated: ${datafiledate}")
 
 putdocx paragraph
 putdocx text ("Input datasets:"),bold
 local nfiles:word count `notesinput'
  putdocx paragraph
 forvalues x =1/`nfiles' {
  local thisfile:word `x' of `notesinput'
 putdocx text ("`thisfile'"),linebreak
 } 
 
 putdocx paragraph
 putdocx text ("Do file used:"),bold
  putdocx paragraph
 putdocx text ("`notesdofile'")
 
 putdocx paragraph
 putdocx text ("Description:"),bold
 putdocx paragraph
 putdocx text ("`notesdesc'")
 
 putdocx paragraph
 putdocx text ("Output datasets:"),bold
  putdocx paragraph
 putdocx text ("`notesoutput'")
 
 putdocx paragraph
 putdocx text ("Anything else: "),bold
 putdocx text ("`notesother'")
 
desc,sh
local myrows=r(k)+1
putdocx table main = (`myrows', 6) 

**** INSERT TABLE OF VARIABLES
 
putdocx table main(1,1) = ("Variable name") , bold
putdocx table main(1,2) = ("Description"), bold
putdocx table main(1,3) = ("Coding" ), bold
putdocx table main(1,4) = ("Records") , bold
putdocx table main(1,5) = ("Type") , bold
putdocx table main(1,6) = ("Source") , bold

local counter=2

*LOOP THROUGH VARIABLES
foreach  v of varlist _all {
di "`v'"
local vname:variable label `v'

*check notes to see whether this variable came from another dataset
local varnote: char `v'[id]

*if another, define a local macro describing the file that made it and put in last col of table
if "`varnote'"~="`id'" {
local source: char `v'[source]
putdocx table main(`counter',6) = ("`source'") 
}

**check type of variable- sting or numeric
cap confirm numeric var `v'
di _rc
*If numeric
if _rc==0 {

count if `v'<.
local vcount=r(N)

local vtype: type `v'

putdocx table main(`counter',1) = ("`v'") 
putdocx table main(`counter',2) = ("`vname'") 
putdocx table main(`counter',5) = ("`vtype'") 

*check if there is a label

local vlabname: value label `v'
*only do this if there is a label
if "`vlabname'" ~= "" {
levelsof `v',local(vlist)
local nlevels:word count `vlist'
if `nlevels'>1 {
putdocx table submain`counter' = (`nlevels', 2) ,memtable  border(all,nil)
}
else {
putdocx table submain`counter' = (1, 2) ,memtable  border(all,nil)
}

local subcounter=1
	foreach vgrp in `vlist' {
	putdocx table submain`counter'(`subcounter',1) = ("`vgrp'") 
	local vname: label (`v') `vgrp'
	putdocx table submain`counter'(`subcounter',2) = (`"`vname'"')
	local subcounter=`subcounter'+1
	}

putdocx table  main(`counter',3) = table(submain`counter') 
}

putdocx table main(`counter',4) = ("`vcount'") 
local counter=`counter'+1

}
** if string variable
else {
putdocx table main(`counter',1) = ("`v'") 
putdocx table main(`counter',2) = ("`vname'") 
putdocx table main(`counter',5) = ("string") 
}

} /*close variable loop */

di "`filename'"
putdocx save "`filename'.docx" , replace 

*} /*close quietly */

noi di as txt `"Results are in {browse "`filename'.docx"}"'



