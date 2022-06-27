*This will make all the folders you need set up to be able to run the ALPHA data sharing do files 
*It will copy the files from the compressed folder we sent into the correct folders on your computer

*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*+=+=+=  THINGS YOU NEED TO SET BEFORE RUNNING THE DO FILE +=+=+=+=
*set sitename - you must use the ALPHA sitename, as used in the filenames within the zip file
global sitename "Karonga"
*set the path to the drive/directory where you want to create the ALPHA folder and all the sub-folders
global alphapath "L:/test_sharing"
*set the location of the zip file 
global zip_location "L:\Data_sharing_to_send\For_zips/ALPHA_sharing_Karonga.zip"


*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
*+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

**************************************************
*	INSTALL USER WRITTEN COMMANDS
**************************************************
*The do files that will be used call on two user-written commands that you may need to install
cap ssc install egenmore 
cap ssc install stpm2

**************************************************
*	CREATE THE FOLDER STRUCTURE
**************************************************

*cd to where you want the new folders set up
cd ${alphapath}

*Make an ALPHA folder and go to it
cap mkdir ALPHA
cd ALPHA

	*Make the next level of directories
	cap mkdir clean_data
	cap mkdir Data_sharing
	cap mkdir DoFiles
	cap mkdir Estimates_incidence
	cap mkdir Estimates_mortality
	cap mkdir Incidence_ready_data
	cap mkdir prepared_data
	cap mkdir Prepared_data_documentation
	cap mkdir Ready_data_mortality

	*Within each directory, add in the sub-folders
	cd clean_data
		cap mkdir "${sitename}"
	cd ..
	cd Data_sharing
		cap mkdir DataFirst
		cd DataFirst
			cap mkdir ALPHA_information
			cap mkdir Blank_paperwork
			cd ..

		cap mkdir Incidence_data_for_sharing

		cap mkdir Mortality_data_for_sharing
		cd Mortality_data_for_sharing
			cap mkdir "${sitename}"
			cap mkdir dobs
			cd ..

		cap mkdir results_comparison
		cd results_comparison
			cap mkdir Incidence
			cap mkdir mortality
			cd ..

		cap mkdir dobs

		cap mkdir Study_forms_and_Doc
		cd ..

	cap mkdir DoFiles
	cd DoFiles
		cap mkdir Analysis
		cap mkdir Common
		cap mkdir Data_for_sharing
		cap mkdir Document
		cap mkdir Prepare_data
		cd ..

	cap mkdir Estimates_Incidence
	cd Estimates_Incidence
		cap mkdir Midpoint_rates
		cap mkdir Post_negative_times
		cd ..

	cap mkdir Estimates_mortality
	cd Estimates_mortality
		cap mkdir "${sitename}"
		cd ..

	cap mkdir Incidence_ready_data
	cd Incidence_ready_data
		cap mkdir "${sitename}"
		cd ..

	cap mkdir Prepared_data
	cd Prepared_data
		cap mkdir "${sitename}"
		cd ..

	cap mkdir Prepared_data_documentation
	cd Prepared_data_documentation
		cap mkdir "${sitename}"
		cd ..

	cap mkdir Ready_data_mortality
	cd Ready_data_mortality
		cap mkdir "${sitename}"
		cd ..

***********************************************************************************
** 	 		COPY OVER FILES
***********************************************************************************
cd ${alphapath}/ALPHA

unzipfile ${zip_location},replace

** datasets to move
*input
copy "${alphapath}/ALPHA/residency_${sitename}.dta" "${alphapath}/ALPHA/Clean_data/${sitename}/residency_${sitename}.dta" ,replace
copy  "${alphapath}/ALPHA/hiv_tests_${sitename}.dta" "${alphapath}/ALPHA/Clean_data/${sitename}/hiv_tests_${sitename}.dta" ,replace
copy "${alphapath}/ALPHA/alpha_metadata.dta" "${alphapath}/ALPHA/Clean_data/alpha_metadata.dta" ,replace
*created (takes a long time to run)
copy  "${alphapath}/ALPHA/post_neg_ages_${sitename}.dta" "${alphapath}/ALPHA\Estimates_Incidence\Post_negative_times/post_neg_ages_${sitename}.dta" ,replace
*output
copy  "${alphapath}/ALPHA/mortality_for_sharing_${sitename}.dta" "${alphapath}/ALPHA\Data_sharing\Mortality_data_for_sharing/${sitename}/mortality_for_sharing_${sitename}.dta",replace
if lower("${sitename}")~="agincourt" {
copy "${alphapath}/ALPHA/incidence_${sitename}.dta" "${alphapath}/ALPHA\Data_sharing\Incidence_data_for_sharing/incidence_${sitename}.dta" ,replace
}

** do files
copy  "${alphapath}/ALPHA/Get_HIV_data_from_hiv_tests_check_residency_make_wide_for_merge.do" "${alphapath}/ALPHA\DoFiles/Prepare_data/Get_HIV_data_from_hiv_tests_check_residency_make_wide_for_merge.do",replace
copy "${alphapath}/ALPHA/prepare_residency_summary_dates.do" "${alphapath}/ALPHA\DoFiles/Prepare_data/prepare_residency_summary_dates.do",replace
copy "${alphapath}/ALPHA/Make_dataset_dictionary_with_char.do" "${alphapath}/ALPHA/dofiles/document/Make_dataset_dictionary_with_char.do" ,replace

copy "${alphapath}/ALPHA/create_hivstatus_detail.do" "${alphapath}/ALPHA\DoFiles\Common\create_hivstatus_detail.do" ,replace
copy "${alphapath}/ALPHA/Create_birth_cohort_from_dob.do" "${alphapath}/ALPHA/DoFiles/Common/Create_birth_cohort_from_dob.do" ,replace

copy "${alphapath}/ALPHA/Cubic_spline_for_postNeg_times_by_age_and_sex_and_fouryear.do" "${alphapath}/ALPHA\DoFiles/Common/Cubic_spline_for_postNeg_times_by_age_and_sex_and_fouryear.do" ,replace
copy "${alphapath}/ALPHA/Make_analysis_file_mortality_by_HIV_status.do" "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_mortality_by_HIV_status.do" ,replace
copy "${alphapath}/ALPHA/Make_analysis_file_incidence_midpoint.do" "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_incidence_midpoint.do" ,replace
copy "${alphapath}/ALPHA/Make_analysis_file_incidence_mi.do"  "${alphapath}/ALPHA\DoFiles\Analysis/Make_analysis_file_incidence_mi.do",replace
copy "${alphapath}/ALPHA/Prepare_mortality_ready_for_sharing_August_2021_dob_round_month.do" "${alphapath}/ALPHA\DoFiles\Data_for_sharing/Prepare_mortality_ready_for_sharing_August_2021_dob_round_month.do" ,replace
copy "${alphapath}/ALPHA/Prepare_incidence_ready_for_sharing_August_2021_dob_round_month.do" "${alphapath}/ALPHA\DoFiles\Data_for_sharing/Prepare_incidence_ready_for_sharing_August_2021_dob_round_month.do" ,replace
copy "${alphapath}/ALPHA/ALPHA_data_sharing_master_from_specs_to_shared_datasets.do" "${alphapath}/ALPHA\DoFiles\Data_for_sharing/ALPHA_data_sharing_master_from_specs_to_shared_datasets.do" ,replace

copy "${alphapath}/ALPHA/Calendar_year_split.do" "${alphapath}/ALPHA\DoFiles\Common\Calendar_year_split.do"   ,replace
copy "${alphapath}/ALPHA/create_fouryear.do" "${alphapath}/ALPHA\DoFiles\Common\create_fouryear.do" ,replace
copy "${alphapath}/ALPHA/create_fiveyear.do" "${alphapath}/ALPHA\DoFiles\Common\create_fiveyear.do" ,replace
copy "${alphapath}/ALPHA/single_year_agegrp_split_including_kids.do" "${alphapath}/ALPHA\DoFiles\Common\single_year_agegrp_split_including_kids.do"   ,replace
copy "${alphapath}/ALPHA/create_agegrp_from_age.do" "${alphapath}/ALPHA\DoFiles\Common\create_agegrp_from_age.do" ,replace
copy "${alphapath}/ALPHA/Five_year_agegrp_split_including_kids.do" "${alphapath}/ALPHA\DoFiles\Common\Five_year_agegrp_split_including_kids.do",replace


*reports/results
if lower("${sitename}")~="agincourt" {
copy "${alphapath}/ALPHA/incidence_comparison_summary_${sitename}.docx"  "${alphapath}/ALPHA\Data_sharing\results_comparison/incidence/incidence_comparison_summary_${sitename}.docx"   ,replace
}
copy "${alphapath}/ALPHA/mortality_comparison_summary_${sitename}.docx" "${alphapath}/ALPHA\Data_sharing\results_comparison/mortality/mortality_comparison_summary_${sitename}.docx"   ,replace
copy "${alphapath}/ALPHA/original_rates_${sitename}.dta"  "${alphapath}/ALPHA\Data_sharing\results_comparison/mortality/original_rates_${sitename}.dta"   ,replace
if lower("${sitename}")~="ifakara"  {
copy "${alphapath}/ALPHA/gates_rates_${sitename}.dta"  "${alphapath}/ALPHA\Data_sharing\results_comparison/mortality/gates_rates_${sitename}.dta"   ,replace
}




***********************************************************************************
** 	 		DELETE EXTRACTED FILES FROM THE ROOT
***********************************************************************************


** datasets to move
*input
cap erase "${alphapath}/ALPHA/residency_${sitename}.dta" 
cap erase  "${alphapath}/ALPHA/hiv_tests_${sitename}.dta" 
cap erase "${alphapath}/ALPHA/alpha_metadata.dta" 
*created (takes a long time to run)
cap erase  "${alphapath}/ALPHA/post_neg_ages_${sitename}.dta" 
*output
cap erase  "${alphapath}/ALPHA/mortality_for_sharing_${sitename}.dta" 
cap erase "${alphapath}/ALPHA/incidence_${sitename}.dta" 


** do files
cap erase  "${alphapath}/ALPHA/Get_HIV_data_from_hiv_tests_check_residency_make_wide_for_merge.do" 
cap erase "${alphapath}/ALPHA/prepare_residency_summary_dates.do"
cap erase  "${alphapath}/ALPHA/Make_dataset_dictionary_with_char.do"


cap erase "${alphapath}/ALPHA/create_hivstatus_detail.do"
cap erase "${alphapath}/ALPHA/Create_birth_cohort_from_dob.do" 

cap erase "${alphapath}/ALPHA/Cubic_spline_for_postNeg_times_by_age_and_sex_and_fouryear.do" 
cap erase "${alphapath}/ALPHA/Make_analysis_file_mortality_by_HIV_status.do" 
cap erase "${alphapath}/ALPHA/Make_analysis_file_incidence_midpoint.do" 
cap erase "${alphapath}/ALPHA/Make_analysis_file_incidence_mi.do"

cap erase "${alphapath}/ALPHA/Prepare_mortality_ready_for_sharing_August_2021_dob_round_month.do" 
cap erase "${alphapath}/ALPHA/Prepare_incidence_ready_for_sharing_August_2021_dob_round_month.do" 
cap erase "${alphapath}/ALPHA/ALPHA_data_sharing_master_from_specs_to_shared_datasets.do" 

cap erase "${alphapath}/ALPHA/Calendar_year_split.do" 
cap erase "${alphapath}/ALPHA/create_fouryear.do" 
cap erase "${alphapath}/ALPHA/create_fiveyear.do" 
cap erase "${alphapath}/ALPHA/single_year_agegrp_split_including_kids.do" 
cap erase "${alphapath}/ALPHA/create_agegrp_from_age.do" 
cap erase "${alphapath}/ALPHA/Five_year_agegrp_split_including_kids.do"

*reports/results
cap erase "${alphapath}/ALPHA/incidence_comparison_summary_${sitename}.docx"  
cap erase "${alphapath}/ALPHA/mortality_comparison_summary_${sitename}.docx" 
cap erase  "${alphapath}/ALPHA/original_rates_${sitename}.dta"  
cap erase  "${alphapath}/ALPHA/gates_rates_${sitename}.dta"  
