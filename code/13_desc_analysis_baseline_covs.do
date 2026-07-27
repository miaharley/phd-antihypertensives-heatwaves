/*=========================================================================
DO FILE NAME:			13_desc_stats_baseline_covs

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

DESCRIPTION OF FILE:	Creates table of baseline covariates for total study population, each treatment group and each analysis
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/13_desc_stats_baseline_covs", text replace

/*****************************************************************
Create dataset of overall study population for baselin characteristics
*****************************************************************/

* Population in C03 analysis
use "$datafile\sccs_main_analysis_patientlist_C03_${outcome}", clear
gen C03=1 if exposure==1 | exposure==2 // create flag for ever exposed to C03
replace C03=0 if exposure==0
drop exposure
* Population in C08 analysis
merge 1:1 patid using "$datafile\sccs_main_analysis_patientlist_C08_${outcome}", nogen
gen C08=1 if exposure==1 | exposure==2 // create flag for ever exposed to C08
replace C08=0 if exposure==0 | exposure==.
drop exposure
* Population in C09 analysis
merge 1:1 patid using "$datafile\sccs_main_analysis_patientlist_C09_${outcome}", nogen
gen C09=1 if exposure==1 | exposure==2 // create flag for ever exposed to C08
replace C09=0 if exposure==0 | exposure==.
drop exposure
* Create flag for people that were exposed to all classes
gen allclasses=1 if C03==1 | C08==1 | C09==1
replace allclasses=0 if allclasses==.

save "$datafile\sccs_main_analysis_patientlist_totalstudypop", replace

/*****************************************************************
Baseline covariates for total study population
*****************************************************************/

putexcel set "$output/desc_anal_baseline_covs.xlsx", sheet("totalstudypop") modify
putexcel B1 = "Total study population"
putexcel A2 = "Sample"
putexcel A3 = "Sex"
putexcel A4 = "Male"
putexcel A5 = "Female"
putexcel A6 = "Age group"
putexcel A7 = "18-40"
putexcel A8 = "40-50"
putexcel A9 = "50-60"
putexcel A10 = "60-70"
putexcel A11 = ">70"
putexcel A12 = "Average consultation months per year"
putexcel A13 = "<3"
putexcel A14 = "3-7"
putexcel A15 = "7-12"


local row 16
putexcel A`row' = "Comorbidities"
foreach disease in $comorbid  {
	local row = `row'+1
	putexcel A`row' = "`disease'"
	local `disease' `row'
}

local row = `row'+1
putexcel A`row' = "Medications 90 days prior"
foreach medication in $medications  {
	local row = `row'+1
	putexcel A`row' = "`medication'"
	local `medication' `row'
}

use "$datafile\sccs_main_analysis_patientlist_totalstudypop", clear

* Add in cormodities and medications at observation start
merge 1:1 patid using "$datafile/covariates/hypertension_comorbid_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_medications_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_annual_consultations", keep(match) nogen

* Sample sizes
count
local sample `r(N)'
putexcel B2 = `sample', nformat("#")

* Sex counts
count if gender==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B4 = "`n_p'"
count if gender==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B5 = "`n_p'"

* Age groups
count if cat_age==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B7 = "`n_p'"
count if cat_age==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B8 = "`n_p'"
count if cat_age==3
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B9 = "`n_p'"
count if cat_age==4
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B10 = "`n_p'"
count if cat_age==5
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B11 = "`n_p'"


* Average consultation months per year
count if cons_cat==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B13 = "`n_p'"
count if cons_cat==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B14 = "`n_p'"
count if cons_cat==3
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B15 = "`n_p'"

* Comorbidities
foreach disease in $comorbid {
count if `disease'==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B``disease''  = "`n_p'"
}

* Comorbidities
foreach medication in $medications {
count if `medication'==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel B``medication''  = "`n_p'"
}


/*****************************************************************
Baseline covariates for all treatment groups
*****************************************************************/

putexcel set "$output/desc_anal_baseline_covs.xlsx", sheet("alltreatmentgroups") modify
putexcel B1 = "Diuretics"
putexcel C1 = "CCBs"
putexcel D1 = "ACEi/ARBs"
putexcel E1 = "All classes"
putexcel F1 = "Unexposed"
putexcel A2 = "Sample"
putexcel A3 = "Sex"
putexcel A4 = "Male"
putexcel A5 = "Female"
putexcel A6 = "Age group"
putexcel A7 = "18-40"
putexcel A8 = "40-50"
putexcel A9 = "50-60"
putexcel A10 = "60-70"
putexcel A11 = ">70"
putexcel A12 = "Average consultation months per year"
putexcel A13 = "<3"
putexcel A14 = "3-7"
putexcel A15 = "7-12"

local row 16
putexcel A`row' = "Comorbidities"
foreach disease in $comorbid  {
	local row = `row'+1
	putexcel A`row' = "`disease'"
	local `disease' `row'
}

local row = `row'+1
putexcel A`row' = "Medications 90 days prior"
foreach medication in $medications  {
	local row = `row'+1
	putexcel A`row' = "`medication'"
	local `medication' `row'
}

local C03 B
local C08 C
local C09 D
local allclasses E

foreach drug in C03 C08 C09 allclasses {

use "$datafile\sccs_main_analysis_patientlist_totalstudypop", clear

* Add in cormodities and medications at observation start
merge 1:1 patid using "$datafile/covariates/hypertension_comorbid_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_medications_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_annual_consultations", keep(match) nogen

keep if `drug'==1

* Sample sizes
count
local sample `r(N)'
putexcel ``drug''2 = `sample', nformat("#")

* Sex counts
count if gender==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''4 = "`n_p'"
count if gender==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''5 = "`n_p'"

* Age groups
count if cat_age==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''7 = "`n_p'"
count if cat_age==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''8 = "`n_p'"
count if cat_age==3
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''9 = "`n_p'"
count if cat_age==4
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''10 = "`n_p'"
count if cat_age==5
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''11 = "`n_p'"


* Average consultation months per year
count if cons_cat==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''13 = "`n_p'"
count if cons_cat==2
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''14 = "`n_p'"
count if cons_cat==3
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''15 = "`n_p'"

* Comorbidities
foreach disease in $comorbid {
count if `disease'==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''``disease''  = "`n_p'"
}

* Comorbidities
foreach medication in $medications {
count if `medication'==1
local n `r(N)'
local p = `n'*100/`sample'
local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
putexcel ``drug''``medication''  = "`n_p'"
}

}


/*****************************************************************
Baseline covariates for each exposure group in each analysis
*****************************************************************/
foreach drug in C03 C08 C09 allclasses{

global drug `drug'
	
putexcel set "$output/desc_anal_baseline_covs.xlsx", sheet("${drug}") modify
putexcel B1 = "Exposed only"
putexcel C1 = "Exposed and unexposed"
putexcel D1 = "Unexposed only"
putexcel A2 = "Sample"
putexcel A3 = "Sex"
putexcel A4 = "Male"
putexcel A5 = "Female"
putexcel A6 = "Age group"
putexcel A7 = "18-40"
putexcel A8 = "40-50"
putexcel A9 = "50-60"
putexcel A10 = "60-70"
putexcel A11 = ">70"
putexcel A12 = "Average consultation months per year"
putexcel A13 = "<3"
putexcel A14 = "3-7"
putexcel A15 = "7-12"


local row 16
putexcel A`row' = "Comorbidities"
foreach disease in $comorbid  {
	local row = `row'+1
	putexcel A`row' = "`disease'"
	local `disease' `row'
}

local row = `row'+1
putexcel A`row' = "Medications 90 days prior"
foreach medication in $medications  {
	local row = `row'+1
	putexcel A`row' = "`medication'"
	local `medication' `row'
}

/*****************************************************************
Fill in sample, sex and age
*****************************************************************/
* Create dataset of drug users and non-users
use "$datafile\sccs_main_analysis_patientlist_${drug}_${outcome}", clear

* Add in cormodities and medications at observation start
merge 1:1 patid using "$datafile/covariates/hypertension_comorbid_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_medications_obstart", keep(match) nogen
merge 1:1 patid using "$datafile/covariates/hypertension_annual_consultations", keep(match) nogen
count

* Sample sizes
count if exposure==2
local exposed_only `r(N)'
putexcel B2 = `exposed_only', nformat("#")
count if exposure==1
local exposed_unexposed `r(N)'
putexcel C2 = `exposed_unexposed', nformat("#")
count if exposure==0
local unexposed_only `r(N)'
putexcel D2 = `unexposed_only', nformat("#")

* Sex counts
foreach sex of numlist 1/2 {
	*exposed only
	tab gender exposure, m matcell(gender_exposure)
	local n = gender_exposure[`sex',3]
	local p = `n'*100/`exposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	local row = 3 + `sex'
	putexcel B`row' = "`n_p'"
	*exposed and unexposed
	tab gender exposure, m matcell(gender_exposure)
	local n = gender_exposure[`sex',2]
	local p = `n'*100/`exposed_unexposed'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel C`row' = "`n_p'"
	*unexposed only
	tab gender exposure, m matcell(gender_exposure)
	local n = gender_exposure[`sex',1]
	local p = `n'*100/`unexposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel D`row' = "`n_p'"
}

* Age groups
foreach age of numlist 1/5 {
	tab cat_age exposure, m matcell(age_exposed)
	*exposed only
	local n = age_exposed[`age',3]
	local p = `n'*100/`exposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	local row = 6 + `age'
	putexcel B`row' = "`n_p'"
	*exposed and unexposed
	local n = age_exposed[`age',2]
	local p = `n'*100/`exposed_unexposed'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel C`row' = "`n_p'"
	*unexposed only
	local n = age_exposed[`age',1]
	local p = `n'*100/`unexposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel D`row' = "`n_p'"
}

* Average consultation months per year
foreach cat of numlist 1/3 {
	tab cons_cat exposure, m matcell(cons_exposure)
	*exposed only
	local n = cons_exposure[`cat',3]
	local p = `n'*100/`exposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	local row = 12 + `cat'
	putexcel B`row' = "`n_p'"
	*exposed and unexposed
	local n = cons_exposure[`cat',2]
	local p = `n'*100/`exposed_unexposed'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel C`row' = "`n_p'"
	*unexposed only
	local n = cons_exposure[`cat',1]
	local p = `n'*100/`unexposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel D`row' = "`n_p'"
}

* Comorbidities
foreach disease in $comorbid {
	tab `disease' exposure, m matcell(`disease'_exposure)
	*exposed only
	local n = `disease'_exposure[2,3]
	local p = `n'*100/`exposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel B``disease'' = "`n_p'"
	*exposed unexposed
	local n = `disease'_exposure[2,2]
	local p = `n'*100/`exposed_unexposed'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel C``disease'' = "`n_p'"
	*unexposed only
	local n = `disease'_exposure[2,1]
	local p = `n'*100/`unexposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel D``disease'' = "`n_p'"
}

* Medications
foreach medication in $medications {
	tab `medication' exposure, m matcell(`medication'_exposure)
	*exposed only
	local n = `medication'_exposure[2,3]
	local p = `n'*100/`exposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel B``medication'' = "`n_p'"
	*exposed unexposed
	local n = `medication'_exposure[2,2]
	local p = `n'*100/`exposed_unexposed'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel C``medication'' = "`n_p'"
	*unexposed only
	local n = `medication'_exposure[2,1]
	local p = `n'*100/`unexposed_only'
	local n_p = string(`n', "%9.0f") + " (" + string(`p', "%9.1f") + ")"
	putexcel D``medication'' = "`n_p'"
}

}

log close

