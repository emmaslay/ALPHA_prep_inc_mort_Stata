********************************************
*** DATA SHARING MASTER DO FILE
********************************************
/*
PREPARES DATA FROM ALPHA RESIDENCY AND HIV TEST SPECS TO PRODUCE 
DATASETS ON HIV MORTALITY AND HIV INCIDENCE FOR SHARING
VIA DATAFIRST
SEPTEMBER 2021

Before running this do file, need to ensure all data and do files (supplied as a zip file) are
in the correct directories. There is a do file to accomplish this- Prepare_directory_structure.do

*/
*+=+=+=  THINGS YOU NEED TO SET BEFORE RUNNING THE DO FILE +=+=+=+=
*set sitename - you must use the ALPHA sitename, as used in the filenames within the zip file
global sitename "Rakai"
*set the path to the drive/directory where you want to create the ALPHA folder and all the sub-folders
global alphapath "L:/test_sharing"
*set the location of the zip file 


do  "${alphapath}/ALPHA\DoFiles/Prepare_data/prepare_residency_summary_dates.do"
do  "${alphapath}/ALPHA\DoFiles/Prepare_data/Get_HIV_data_from_hiv_tests_check_residency_make_wide_for_merge.do"

do "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_incidence_midpoint.do"
do "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_incidence_mi.do"  
do  "${alphapath}/ALPHA\DoFiles/Common/Cubic_spline_for_postNeg_times_by_age_and_sex_and_fouryear.do" 
do "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_mortality_by_HIV_status.do" 









