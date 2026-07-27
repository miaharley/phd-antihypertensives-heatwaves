/*=========================================================================
DO FILE NAME:			_masterdo_v4

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

Aim: 					Runs all do files
*=============================================================================*/

macro drop _all

do "Z:\Mia\antihyp\dofile\_paths.do"

/******************************************************************
Import data
******************************************************************/
do "$dofiles\0_import_clinical_data.do"
do "$dofiles\1_import_temp_data.do" 

/******************************************************************
Extract clinical codes
******************************************************************/
global codelists_excel "Z:\Mia\antihyp\ICD10_ATC_CODES_ZW_miacopy.xlsx"

do "$dofiles\2_extract_hypertension_dx.do"
do "$dofiles\3_extract_covariates.do"
do "$dofiles\4_extract_outcomes_v2.do"
do "$dofiles\5_extract_antihyp_rx_v2.do"

/******************************************************************
Identify exposure periods for each class of medications
******************************************************************/
global graceperiod 30

foreach drug in C03 C08 C09 allclasses {
global drug `drug'
do "$dofiles\6_create_antihyp_episodes.do"
do "$dofiles\7_create_antihyp_heatwave_intervals.do"
do "$dofiles\8_create_noantihyp_heatwave_intervals.do"
}

macro drop _global drug
/******************************************************************
SCCS main analysis, interaction antihyp and heat on heat illness
******************************************************************/
global outcome heat_illness
foreach drug in C03 C08 C09 allclasses  {
global drug `drug'
do "$dofiles\9_sccs_prepare_dataset.do"
do "$dofiles\10_sccs_main_analysis.do"
}

macro drop _global drug
macro drop _global outcome
/******************************************************************
Subgroup analysis, by class and adjusted for other hypertensives
******************************************************************/
global outcome heat_illness
do "$dofiles\11_identify_antihypclass_interval_v2.do"

foreach drug in C03 C08 C09 allclasses {
global drug `drug'
do "$dofiles\12_sccs_subgroup_analysis_byclass.do"
}

macro drop _global drug
macro drop _global outcome

/******************************************************************
Descriptive analyses
******************************************************************/
global outcome heat_illness
do "$dofiles\13_desc_analysis_baseline_covs.do"
do "$dofiles\14_desc_analysis_tempdata"
do "$dofiles\15_desc_analysis_antihyps.do"

macro drop _global drug
macro drop _global outcome

/******************************************************************
Sensitivity analyses
******************************************************************/
global outcome heat_illness
foreach drug in allclasses {
global drug `drug'
do "$dofiles\16_sccs_sens_analysis_summeronly.do"
do "$dofiles\17_sccs_sens_analysis_exclhosp_v2.do"
do "$dofiles\18_sccs_sens_analysis_firstoutcome.do"
}
do "$dofiles\19_sccs_sens_analysis_nointeraction_v2.do"

macro drop _global drug
macro drop _global outcome

/******************************************************************
Describe all variables in all datafiles (for editing do files remotely)
*****************************************************************
do "$dofiles\_describe_data.do"

*/
