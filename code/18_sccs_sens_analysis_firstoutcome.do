/*=========================================================================
DO FILE NAME:			18_sccs_sens_analysis_firstoutcome

AUTHOR:					Mia Harley

VERSION:				v1	
					
DATABASE:				Japanese claims data

DESCRIPTION OF FILE:	Runs SCCS (main and subgroup analysis) but restrict to first heat illness event
*=========================================================================*/

* create new log
cap log close
log using "${logfiles}/18_sccs_sens_analysis_firstoutcome_${drug}_${outcome}", text replace

/*****************************************************************/
* 1. Create SCCS analysis dataset for first outcome
*****************************************************************/
use "$datafile/hypertension_${drug}_heatwave_intervals_all_antihypadjust", clear
rename st_st obs_start
rename st_en obs_end

di "Join with with $outcome events"
joinby patid using "$datafile\hypertension_${outcome}_first", unmatched(master)
drop icd10 _merge

* Create outcome variable
replace eventstart = . if eventstart!=. & eventstart > obs_end
replace eventstart = . if eventstart!=. & eventstart < obs_start

gen outcome_ind = 1 if eventstart >= interstart & eventstart <= interend
replace outcome_ind = 0 if outcome_ind == .

* remove duplicates
gsort patid interstart interend -outcome_ind
bysort patid interstart interend: keep if _n == 1

* remove those who do not have an outcome during observation period
bysort patid: egen max_outcome = max(outcome_ind)
drop if max_outcome == 0
drop max_outcome

* Create variable for interval (offset)
gen interval = interend - interstart + 1
gen loginterval = log(interval)

* View number of event in each risk period
tab outcome_ind intertype,m

assert interstart <= obs_end
assert interend >= obs_start

cou if eventstart>obs_end & eventstart !=.
cou if eventstart<obs_start & eventstart !=.


gen age_index = (obs_start-dob)/365.25
gen     cat_age=1 if age_index>=18 & age_index<40
replace cat_age=2 if age_index>=40 & age_index<50
replace cat_age=3 if age_index>=50 & age_index<60
replace cat_age=4 if age_index>=60 & age_index<70
replace cat_age=5 if age_index>=70 
cou if cat_age ==.
drop age_index

drop unique_interval
gen unique_interval = _n

destring(patid), replace

save "$datafile\sccs_sens_analysis_firstoutcome_${drug}_${outcome}.dta", replace

/*****************************************************************
Set up excel
*****************************************************************/

putexcel set "$output/sccs_sens_analysis_firstoutcome_${outcome}.xlsx", sheet("${drug}") modify

putexcel B1 = "With drug"
putexcel F1 = "Without drug"
putexcel B2 = "Events"
putexcel C2 = "Person years"
putexcel D2 = "IRR"
putexcel E2 = "95% CIs"
putexcel F2 = "Events"
putexcel G2 = "Person years"
putexcel H2 = "IRR"
putexcel I2 = "95% CIs"
putexcel J2 = "P-interaction"
putexcel A3 = "Baseline"
putexcel A4 = "Pre-heatwave"
putexcel A5 = "Heatwave"
putexcel A6 = "Post-heatwave"

/*****************************************************************
Fill in events and person years
*****************************************************************/

********** With drug

use "$datafile\sccs_sens_analysis_firstoutcome_${drug}_${outcome}.dta", clear

* Baseline
preserve
keep if intertype==0 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & drugexposed==1
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel C6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel B6 = `events', nformat("#")
restore

********** Without drug

* Baseline
preserve
keep if intertype==0 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G3 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F3 = `events', nformat("#")
restore

* Pre-heatwave
preserve
keep if intertype==1 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G4 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F4 = `events', nformat("#")
restore

* Heatwave
preserve
keep if intertype==2 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G5 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F5 = `events', nformat("#")
restore

* Post-heatwave
preserve
keep if intertype==3 & drugexposed==0
summarize interval, meanonly
local patient_years = (r(sum)/365.25)
putexcel G6 = `patient_years', nformat("#.##")
count if outcome_ind==1
local events = `r(N)'
putexcel F6 = `events', nformat("#")
restore

/*****************************************************************
Run SCCS using conditional Poisson regression
*****************************************************************/

if "${drug}" == "C03" {	
local antihypadjust i.adjustantihyp_C08 i.adjustantihyp_C09
}

if "${drug}" == "C08" {	
local antihypadjust i.adjustantihyp_C03 i.adjustantihyp_C09
}

if "${drug}" == "C09" {	
local antihypadjust i.adjustantihyp_C03 i.adjustantihyp_C08
}

if "${drug}" == "allclasses" {	
}

*interaction
xi i.intertype*i.drugexposed i.season i.age_gp
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _IintXdru_* _Iseason_* _Iage_gp_* `antihypadjust', fe i(patid) offset(loginterval) irr
est store modA

di "With drug exposure in risk period 1"
lincom _Iintertype_1 + _IintXdru_1_1, eform 
putexcel D4 = (string(r(estimate), "%9.2f"))
putexcel E4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "With drug exposure in risk period 2"
lincom _Iintertype_2 + _IintXdru_2_1, eform 
putexcel D5 = (string(r(estimate), "%9.2f"))
putexcel E5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "With drug exposure in risk period of 3"
lincom _Iintertype_3 + _IintXdru_3_1, eform 
putexcel D6 = (string(r(estimate), "%9.2f"))
putexcel E6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

di "Without drug exposure in risk period of 1"
lincom _Iintertype_1, eform 
putexcel H4 = (string(r(estimate), "%9.2f"))
putexcel I4 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))

di "Without drug exposure in risk period of 2"
lincom _Iintertype_2, eform
putexcel H5 = (string(r(estimate), "%9.2f"))
putexcel I5 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f"))  

di "Without drug exposure in risk period of 3"
lincom _Iintertype_3, eform
putexcel H6 = (string(r(estimate), "%9.2f"))
putexcel I6 = (string(r(lb), "%9.2f") + "-" + string(r(ub), "%9.2f")) 

*no interaction
xtpoisson outcome_ind _Iintertype_*  _Idrugexpos_* _Iseason_* _Iage_gp_* `antihypadjust', fe i(patid) offset(loginterval) irr
est store modB

*interaction test
lrtest modA modB
putexcel J3 = (string(r(p), "%9.2f"))
