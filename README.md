# ALPHA_prep_inc_mort_Stata
This repository contains the code needed to go from the ALPHA data specs to the two analysis-ready datasets used for estimating 1) mortality by HIV status and 2) HIV incidence.  The code requires the data to be in ALPHA spec format to run. </p>
<p>It contains a do file to set up the directory structure which is essential for the analysis to run (Prepare_directory_structure.do). This is written for a set of zipped do files and will unzip them, create the directory structure and add the do files in the right place.</p>
<p>Another do file, ALPHA_data_sharing_master_from_specs_to_inc_and_mort.do, runs the other do files in the right order, once the directory structure is set up.
