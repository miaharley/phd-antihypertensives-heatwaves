/*=========================================================================
DO FILE NAME:			11_identify_antihypclass_interval_v2

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

DESCRIPTION OF FILE:	identifies how many/ which other classes of antihypertensives are used during exposure intervals to adjust for other classes
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/11_identify_antihypclass_interval_${outcome}_v2", text replace


/*****************************************************************/
* C03 flag use of other antihypertensives
*****************************************************************/
foreach drug in C08 C09 {
	
use "$datafile/hypertension_C03_heatwave_intervals_all", clear
joinby patid using "$datafile/antihyp_`drug'_rxall.dta", unmatched(master)

*keep prescriptions overlapping with interval
drop if rxst ==.
drop if rxst < interstart & rxen < interstart
drop if rxst > interend & rxen > interend

*create flag for other antihypertensive exposure during interval
duplicates drop unique_interval, force
gen adjustantihyp_`drug'=1

*retrieve intervals without other antihypertensives
merge 1:1 unique_interval using "$datafile/hypertension_C03_heatwave_intervals_all", nogen
replace adjustantihyp_`drug'=0 if adjustantihyp_`drug'==.

*tidy and save
keep patid unique_interval adjustantihyp_`drug'
tempfile C03_adjustantihyp_`drug'
save `C03_adjustantihyp_`drug''
}

use `C03_adjustantihyp_C08', clear
merge 1:1 unique_interval using `C03_adjustantihyp_C09', nogen
merge 1:1 unique_interval using "$datafile/hypertension_C03_heatwave_intervals_all", nogen
save "$datafile/hypertension_C03_heatwave_intervals_all_antihypadjust", replace

/*****************************************************************/
* C08 flag use of other antihypertensives
*****************************************************************/
foreach drug in C03 C09 {
use "$datafile/hypertension_C08_heatwave_intervals_all", clear
joinby patid using "$datafile/antihyp_`drug'_rxall.dta", unmatched(master)
drop _merge

*keep prescriptions overlapping with interval
drop if rxst ==.
drop if rxst < interstart & rxen < interstart
drop if rxst > interend & rxst > interend

*create flag for other antihypertensive exposure during interval
duplicates drop unique_interval, force
gen adjustantihyp_`drug'=1

*retrieve intervals without other antihypertensives
merge 1:1 unique_interval using "$datafile/hypertension_C08_heatwave_intervals_all", nogen
replace adjustantihyp_`drug'=0 if adjustantihyp_`drug'==.

*tidy and save
keep patid unique_interval adjustantihyp_`drug'
tempfile C08_adjustantihyp_`drug'
save `C08_adjustantihyp_`drug''
}

use `C08_adjustantihyp_C03', clear
merge 1:1 unique_interval using `C08_adjustantihyp_C09', nogen
merge 1:1 unique_interval using "$datafile/hypertension_C08_heatwave_intervals_all", nogen
save "$datafile/hypertension_C08_heatwave_intervals_all_antihypadjust", replace

/*****************************************************************/
* C09 flag use of other antihypertensives
*****************************************************************/
foreach drug in C03 C08 {
use "$datafile/hypertension_C09_heatwave_intervals_all", clear
joinby patid using "$datafile/antihyp_`drug'_rxall.dta", unmatched(master)
drop _merge

*keep prescriptions overlapping with interval
drop if rxst ==.
drop if rxst < interstart & rxen < interstart
drop if rxst > interend & rxst > interend

*create flag for other antihypertensive exposure during interval
duplicates drop unique_interval, force
gen adjustantihyp_`drug'=1

*retrieve intervals without other antihypertensives
merge 1:1 unique_interval using "$datafile/hypertension_C09_heatwave_intervals_all", nogen
replace adjustantihyp_`drug'=0 if adjustantihyp_`drug'==.

*tidy and save
keep patid unique_interval adjustantihyp_`drug'
tempfile C09_adjustantihyp_`drug'
save `C09_adjustantihyp_`drug''
}

use `C09_adjustantihyp_C03', clear
merge 1:1 unique_interval using `C09_adjustantihyp_C08', nogen
merge 1:1 unique_interval using "$datafile/hypertension_C09_heatwave_intervals_all", nogen
save "$datafile/hypertension_C09_heatwave_intervals_all_antihypadjust", replace

/*****************************************************************/
* All classes - count how many classes are used during exposure periods
*****************************************************************/	
use "$datafile/hypertension_allclasses_heatwave_intervals_all", clear

*temporarily drop drug unexposed intervals
drop if drugexposed==0

*keep prescriptions overlapping with interval
joinby patid using "$datafile/antihyp_allclasses_rxall.dta", unmatched(master)
drop if rxst ==.
drop if rxst < interstart & rxen < interstart
drop if rxst > interend & rxst > interend
drop _merge

*count number of classes during interval
bysort patid unique_interval drug_class: keep if _n==1
bysort patid unique_interval: gen number_classes = _N	
duplicates drop unique_interval, force
assert number_classes>=1 & number_classes<=3

*retrieve drug unexposed intervals
merge 1:1 unique_interval using "$datafile/hypertension_allclasses_heatwave_intervals_all", nogen
replace number_classes=0 if number_classes==.

* create a flag for multiple drug exposure
gen multiple_drug = 2 if number_classes > 1
replace multiple_drug = 1 if number_classes==1
replace multiple_drug=0 if  multiple_drug==.

*tidy and save
save "$datafile/hypertension_allclasses_heatwave_intervals_all_antihypadjust", replace
	

log close