/*=========================================================================
DO FILE NAME:			2_extract_hypertension_dx

AUTHOR:					Mia Harley
VERSION:				v1			
DATABASE:				Japanese claims data

Aim: 					To extract hypertension diagnoses and identify people with hypertension
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/2_extract_hypertension_dx", text replace

/******************************************************************
Import codelists
******************************************************************/
*create icd10 codelists
foreach disease in hypertension {
import excel using ${codelists_excel}, sheet("icd10_`disease'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
gen icd10 = icd_3 + icd_5 if !missing(icd_5)
replace icd10 = icd_3 if missing(icd_5)
drop icd_3 icd_5
save "$codelists/icd10_`disease'", replace
}
*create icd10 codelists - 3 digits only					
foreach disease in hypertension {
import excel using ${codelists_excel}, sheet("icd10_`disease'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
keep if missing(icd_5)
gen icd10 = icd + "-"
drop icd_3 icd_5 icd
save "$codelists/icd10_3digit_`disease'", replace
}

/******************************************************************
*Identify all hypertension diagnoses
******************************************************************/
				
foreach disease in hypertension {
*icd10
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_`disease'", keep(match) keepusing(icd10) nogen
save "$datafile/icd10_`disease'_all", replace

*icd10 - 3 digits only
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_3digit_`disease'", keep(match) keepusing(icd10) nogen
save "$datafile/icd10_threedigit_`disease'_all", replace

*append
use "$datafile/icd10_`disease'_all", clear
append using "$datafile/icd10_threedigit_`disease'_all"
duplicates drop patid icd10 eventstart, force
save "$datafile/`disease'_dxall", replace

*erase unneccessary files
erase "$datafile/icd10_`disease'_all.dta"
erase "$datafile/icd10_threedigit_`disease'_all.dta"
}

/*************************************
*People with hypertension
**************************************/

use "$datafile/hypertension_dxall", clear
sort patid eventstart
bysort patid: keep if _n==1

*get patient info
merge 1:1 patid using "$datafile/patient.dta", keep(master match) nogen

*set up observation start and end dates
gen obs_start = max(eventstart, regstart, d($studystartdate))
gen obs_end = min(regend, d($studyenddate))
format obs_start obs_end %td

*keep people with age >=18 at the start of follow-up
gen age_index = (obs_start-dob)/365.25
drop if age_index <18

*remove people with invalid observation period
drop if obs_end < obs_start
drop if obs_start==obs_end

*Hypertension indicator
gen hypertension=1

*tidy and save
rename eventstart hypertension_dx_date
keep patid obs_start obs_end dob gender hypertension hypertension_dx_date
save "$datafile/hypertension_patients", replace


/*************************************
*Identify people with hypertension who experienced a heatwave
**************************************/

use "$datafile/hypertension_patients", clear

*set up risk period (heatwave)
gen obs=1
joinby obs using "$datafile\MEANT_heatwave_tsukuba_date"
gen exposure = 1 if obs_start<=hw_start & hw_start<=obs_end
replace exposure = 1 if obs_start<=hw_end & hw_end<=obs_end

*Remove those who did not experience heatwave during observation period
bysort patid: egen max_exposure = max(exposure)
keep if max_exposure == 1

gen exp_st = max(hw_start, obs_start)
gen exp_en = min(hw_end, obs_end)
format exp_st exp_en %td

drop if exp_st > exp_en

drop obs exposure max_exposure

save "$datafile/hypertension_heatwave.dta", replace


log close
