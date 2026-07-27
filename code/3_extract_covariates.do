/*=========================================================================
DO FILE NAME:			3_extract_covariates

AUTHOR:					Mia Harley
VERSION:				v1			
DATABASE:				Japanese claims data

Aim: 					To extract all covariate data for descriptive analysis
*=============================================================================*/

* create new log
cap log close
log using "${logfiles}/3_extract_covariates", text replace

/******************************************************************
Import comorbid codelists
******************************************************************/
*create icd10 codelists
foreach disease in ischaemic_heart_disease heart_failure venous_thromboembolism cerebrovascular_disease diabetes chronic_renal_disease copd {
import excel using ${codelists_excel}, sheet("icd10_`disease'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
gen icd10 = icd_3 + icd_5 if !missing(icd_5)
replace icd10 = icd_3 if missing(icd_5)
drop icd_3 icd_5
save "$codelists/icd10_`disease'", replace
}

*create icd10 codelists - 3 digits only					
foreach disease in ischaemic_heart_disease heart_failure venous_thromboembolism cerebrovascular_disease diabetes chronic_renal_disease copd {
import excel using ${codelists_excel}, sheet("icd10_`disease'") firstrow allstring clear
gen icd_3 = substr(icd,1,3)
gen icd_5 = substr(icd,5,5)
keep if missing(icd_5)
gen icd10 = icd + "-"
drop icd_3 icd_5 icd
save "$codelists/icd10_3digit_`disease'", replace
}

* import cancer codelist seperately (different format)
import excel using ${codelists_excel}, sheet("icd10_cancer") firstrow allstring clear
drop icd description C
rename icd_detail icd_3
save "$codelists/icd10_3digit_cancer", replace

/******************************************************************
Identify comorbid codes
******************************************************************/

foreach disease in ischaemic_heart_disease heart_failure venous_thromboembolism cerebrovascular_disease diabetes chronic_renal_disease copd {
*icd10
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_`disease'", keep(match) keepusing(icd10) nogen
save "$datafile/covariates/icd10_`disease'_all", replace

*icd10 - 3 digits only
use "$datafile/diagnosis_all.dta", clear
merge m:1 icd10 using "$codelists/icd10_3digit_`disease'", keep(match) keepusing(icd10) nogen
save "$datafile/covariates/icd10_threedigit_`disease'_all", replace

*append
use "$datafile/covariates/icd10_`disease'_all", clear
append using "$datafile/covariates/icd10_threedigit_`disease'_all"
duplicates drop patid icd10 eventstart, force
save "$datafile/covariates/`disease'_dxall", replace

*erase unneccessary files
erase "$datafile/covariates/icd10_`disease'_all.dta"
erase "$datafile/covariates/icd10_threedigit_`disease'_all.dta"
}

* identify cmd codes
use "$datafile/diagnosis_all.dta", clear
keep if strmatch(icd10,"F32*") | strmatch(icd10,"F33*") | strmatch(icd10,"F41*")
duplicates drop patid icd10 eventstart, force
save "$datafile/covariates/cmd_dxall", replace

* identify smi codes
use "$datafile/diagnosis_all.dta", clear
keep if strmatch(icd10,"F20*") | strmatch(icd10,"F21*") | strmatch(icd10,"F22*") | strmatch(icd10,"F25*") | strmatch(icd10,"F30*") | strmatch(icd10,"F31*")
duplicates drop patid icd10 eventstart, force
save "$datafile/covariates/smi_dxall", replace

* identify cancer codes
use "$datafile/diagnosis_all.dta", clear
gen icd_3 = substr(icd10,1,3)
merge m:1 icd_3 using "$codelists/icd10_3digit_cancer", keep(match) keepusing(icd_3) nogen
duplicates drop patid icd_3 eventstart, force
drop icd_3
save "$datafile/covariates/cancer_dxall", replace


/******************************************************************
Identify medication codes **copied from Angel's, adding diabetes medications and psychotropics
******************************************************************/

*Diabetes medications
use "$datafile/drug.dta", clear
keep if strmatch(who_atc,"A10B*") 
save "$datafile/covariates/diabetes_medications_rxall.dta", replace	

*Antidepressants
use "$datafile/drug.dta", clear
keep if strmatch(who_atc,"N06A*") 
save "$datafile/covariates/antidepressants_rxall.dta", replace

*Antipsychotics
use "$datafile/drug.dta", clear
keep if strmatch(who_atc,"N05A*") 
save "$datafile/covariates/antipsychotics_rxall.dta", replace

*Beta blocker
use "$datafile/drug.dta", clear
keep if substr(who_atc,1,3) == "C07" 
save "$datafile/covariates/betablockers_rxall.dta", replace	

*oral anticoagulants
use "$datafile/drug.dta", clear
keep if substr(who_atc,1,7) == "B01AA03" | substr(who_atc,1,7) == "B01AE07" | ///
substr(who_atc,1,7) == "B01AF01" | substr(who_atc,1,7) == "B01AF02" | ///
substr(who_atc,1,7) == "B01AF03" 
save "$datafile/covariates/oac_rxall.dta", replace

*statin
use "$datafile/drug.dta", clear
keep if substr(who_atc,1,7) == "A10BH51" | substr(who_atc,1,7) == "A10BH52" | ///
substr(who_atc,1,5) == "C10AA" | substr(who_atc,1,7) == "C10BA01" | ///
substr(who_atc,1,7) == "C10BA02" | substr(who_atc,1,7) == "C10BA03" | ///
substr(who_atc,1,7) == "C10BA04" | substr(who_atc,1,7) == "C10BA05" | ///
substr(who_atc,1,7) == "C10BA06" | substr(who_atc,1,7) == "C10BA07" | ///
substr(who_atc,1,7) == "C10BA08" | substr(who_atc,1,7) == "C10BA09" | ///
substr(who_atc,1,7) == "C10BA11" | substr(who_atc,1,7) == "C10BA12" | ///
substr(who_atc,1,5) == "C10BX"
save "$datafile/covariates/statins_rxall.dta", replace

*antibiotics
use "$datafile/drug.dta", clear
keep if substr(who_atc,1,5) == "A07AA" | substr(who_atc,1,5) == "G01AA" | ///
substr(who_atc,1,5) == "G01BA" | substr(who_atc,1,3) == "J01" | ///
substr(who_atc,1,5) == "J04AB" | substr(who_atc,1,5) == "R02AB"
save "$datafile/covariates/antibiotics_rxall.dta", replace

*PPI 
use "$datafile/drug.dta", clear
keep if substr(who_atc,1,5) == "A02BC" | substr(who_atc,1,7) == "B01AC56"
save "$datafile/covariates/ppi_rxall.dta", replace


/******************************************************************
Create variables for comorbidities at observation start
******************************************************************/
* Create individual comorbid variables
foreach disease in $comorbid {
use "$datafile/covariates/`disease'_dxall", clear
merge m:1 patid using "$datafile/hypertension_patients", keep(match using) nogen
gen `disease'_base =1 if eventstart!=. & eventstart <= obs_start
bysort patid: egen `disease'= max(`disease'_base)
duplicates drop patid, force
replace `disease' = 0 if `disease' == .
label var `disease' "`disease' prevalence at observation start date"
keep patid `disease'
save "$datafile/covariates/`disease'", replace
}

* Combine into one dataset
use "$datafile/hypertension_patients", clear
save "$datafile/covariates/hypertension_comorbid_obstart", replace
foreach disease in $comorbid {
use "$datafile/covariates/hypertension_comorbid_obstart", clear
merge 1:1 patid using "$datafile/covariates/`disease'", keep(master match) nogen
save "$datafile/covariates/hypertension_comorbid_obstart", replace
erase "$datafile/covariates/`disease'.dta"
}

/******************************************************************
Create variables for medications at observation start
******************************************************************/

* Create individual medication variables
foreach medication in $medications {
use "$datafile/covariates/`medication'_rxall.dta", clear
merge m:1 patid using "$datafile/hypertension_patients", keep(match using) nogen
gen `medication'_base=1 if rxst!=. & obs_start-90<=rxst & rxst<=obs_start
bysort patid: egen `medication' = max(`medication'_base)
duplicates drop patid, force
replace `medication' = 0 if `medication' == .
drop `medication'_base
label var `medication' "`medication' use at observation start date "
keep patid `medication'
save "$datafile/covariates/`medication'", replace
}

* Combine into one dataset
use "$datafile/hypertension_patients", clear
save "$datafile/covariates/hypertension_medications_obstart", replace
foreach medication in $medications {
use "$datafile/covariates/hypertension_medications_obstart", clear
merge 1:1 patid using "$datafile/covariates/`medication'", keep(master match) nogen
save "$datafile/covariates/hypertension_medications_obstart", replace
erase "$datafile/covariates/`medication'.dta"
}

/******************************************************************
Health seeking behaviour - annual health check up
******************************************************************/
use "$datafile/annual_health_checkup.dta", clear
merge m:1 patid using "$datafile/hypertension_patients", keep(match) nogen
keep patid obs_start obs_end checkup_date gender dob
order patid obs_start obs_end checkup_date gender dob 
duplicates drop patid checkup_date, force
keep if checkup_date >= obs_start & checkup_date <= obs_end
bysort patid (checkup_date): gen num_checks=_N
gen obs_duration = obs_end-obs_start
gen obs_duration_years = obs_duration/365.25
gen av_num_checks = num_checks/obs_duration_years
merge m:1 patid using "$datafile/hypertension_patients", keep(match using) nogen
replace av_num_checks=0 if av_num_checks==.
gen checks_cat = 1 if av_num_checks==0
replace checks_cat = 2 if av_num_checks>0 & av_num_checks<1
replace checks_cat = 3 if av_num_checks>=1
keep patid av_num_checks checks_cat
duplicates drop patid av_num_checks checks_cat, force
save "$datafile/covariates/hypertension_annual_checkups", replace

/******************************************************************
Health seeking behaviour - monthly health care visit rate
******************************************************************/

use "$datafile/diagnosis_all.dta", clear
merge m:1 patid using "$datafile/hypertension_patients", keep(match) nogen
keep if eventstart >= obs_start & eventstart <= obs_end
gen monthyear_event = mofd(eventstart)
format monthyear_event %tm
bysort patid monthyear_event (eventstart): keep if _n==1
bysort patid: gen cons_months=_N
gen obs_start_my = ym(year(obs_start), month(obs_start))
gen obs_end_my = ym(year(obs_end), month(obs_end))
format obs_start_my obs_end_my %tm
gen obs_months = obs_end_my - obs_start_my + 1
gen av_cons_months = round((cons_months/obs_months)*12)
gen cons_cat=.
replace cons_cat=1 if av_cons_months>=0 & av_cons_months<3
replace cons_cat=2 if av_cons_months>=3 & av_cons_months<=7
replace cons_cat=3 if av_cons_months>=8 & av_cons_months<=12
keep patid av_cons_months cons_cat
duplicates drop patid av_cons_months cons_cat, force
save "$datafile/covariates/hypertension_annual_consultations", replace

log close
