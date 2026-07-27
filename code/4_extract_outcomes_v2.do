/*=========================================================================
DO FILE NAME:			4_extract_outcomes_v2

AUTHOR:					Mia Harley
VERSION:				v1			
DATABASE:				Japanese claims data

Aim: 					To extract outcomes and identify people with hypertension who experienced outcome
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/4_extract_outcomes", text replace

/******************************************************************
Extract codes for heat illness
******************************************************************/

* Heat illness
use "$datafile/diagnosis_all.dta", clear
keep if substr(icd10,1,3)=="T67" | substr(icd10,1,3)=="E86" |  substr(icd10,1,3)=="E87" |substr(icd10,1,3)=="X30" 
save "$datafile/heat_illness_dxall", replace

** Stroke no longer used as outcome due to insufficient power
/******************************************************************
Import codelist for stroke 
*****************************************************************
*create icd10 codelists
foreach outcome in stroke {
import excel using ${codelists_excel}, sheet("icd10_`outcome'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
gen icd10 = icd_3 + icd_5 if !missing(icd_5)
replace icd10 = icd_3 if missing(icd_5)
drop icd_3 icd_5
save "$codelists/icd10_`outcome'", replace
}
*create icd10 codelists - 3 digits only					
foreach outcome in stroke {
import excel using ${codelists_excel}, sheet("icd10_`outcome'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
keep if missing(icd_5)
gen icd10 = icd + "-"
drop icd_3 icd_5 icd
save "$codelists/icd10_3digit_`outcome'", replace
}

/******************************************************************
Identify all stroke diagnoses
******************************************************************/
foreach outcome in stroke {				
*icd10
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_`outcome'", keep(match) keepusing(icd10) nogen
save "$datafile/icd10_`outcome'_all", replace

*icd10 - 3 digits only
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_3digit_`outcome'", keep(match) keepusing(icd10) nogen
save "$datafile/icd10_threedigit_`outcome'_all", replace

*append
use "$datafile/icd10_`outcome'_all", clear
append using "$datafile/icd10_threedigit_`outcome'_all"
duplicates drop patid icd10 eventstart, force
save "$datafile/`outcome'_dxall", replace

*erase unneccessary files
erase "$datafile/icd10_`outcome'_all.dta"
erase "$datafile/icd10_threedigit_`outcome'_all.dta"
}
*/

/******************************************************************
Identify outcome events among hypertensive patients
*****************************************************************/
foreach outcome in heat_illness {
	
*all diagnoses
use "$datafile/`outcome'_dxall", clear
merge m:1 patid using "$datafile/hypertension_patients", keep(match) nogen
drop if eventstart < obs_start
drop if eventstart > obs_end
gen `outcome'=1
save "$datafile/hypertension_`outcome'_all", replace

*Create dataset of first record ever
use "$datafile/hypertension_`outcome'_all", clear
sort patid eventstart
bysort patid: keep if _n==1
count
save "$datafile/hypertension_`outcome'_first", replace

*Create dataset with all records that are 30 days apart
use "$datafile/hypertension_`outcome'_all", clear
duplicates drop patid eventstart, force
sort patid eventstart
bysort patid: gen day_diff = eventstart[_n] - eventstart[_n-1] // should I take the eventend for inpatient cases?
bysort patid: gen cum_daydiff = sum(day_diff)
drop if cum_daydiff < 30 & cum_daydiff > 0
save "$datafile/hypertension_`outcome'_multiple", replace

}

log close